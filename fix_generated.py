#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
from collections import defaultdict


PATHS_INDEX_FILE = 'paths/index.yaml'
GENERATED_FILES_DIR = 'generated/cowboy/routes'

REST_API_RE = re.compile(r'^(?P<header>.*?\[\n).*\n(?P<footer>\s*]\..*)$',
                         flags=re.DOTALL)

OPERATIONS_RE = re.compile(r'(?<=(\[|,)\n)'
                           r'(?P<operation>\s+%%.+?\{<<"(?P<path>.+?)">>.+?method = \'(?P<method>GET|DELETE|PATCH|POST|PUT)\',.+?\},?\n)'
                           r'(?=\s*(%%|\]))', flags=re.DOTALL)


def get_paths_ordering():
    with open(PATHS_INDEX_FILE, 'r') as f:
        return [re.sub(r'{(.*?)}', ':\g<1>', line.rstrip(':\n'))
                for line in f
                if line.startswith('/') and line.endswith(':\n')]


def fix_paths_ordering(routes_module_content):
    header, footer = REST_API_RE.match(routes_module_content).groups()

    rest_routes = defaultdict(list)
    for rest_route in OPERATIONS_RE.finditer(routes_module_content):
        path = rest_route.group('path')
        method = rest_route.group('method')
        operation = rest_route.group('operation')
        rest_routes[path].append((method, 
                                  operation.replace(':path">>', '[...]">>')))

    operations = ''.join(operation 
                         for path in get_paths_ordering()
                         for _, operation in sorted(rest_routes[path]))
    return header + operations + footer


def fix_generated_routes_module(routes_module_path):
    with open(routes_module_path, 'r+') as f:

        # Fix multiline comments.
        lines = f.readlines()
        new_lines = []
        for line in lines:
            if '\\n' in line.rstrip():
                pos = line.find('%%')
                if pos >= 0:
                    parts = filter(lambda p: p, line[pos + 3:].rstrip().split('\\n'))
                    parts = map(lambda p: ' ' * pos + '%% ' + p + '\n', parts)
                    new_lines.extend(parts)
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)

        content = ''.join(new_lines)
        content = fix_paths_ordering(content)

        # Fix syntax and substitute invalid character sequences.
        content = re.sub(r',(\s*[}\]\)])', '\g<1>', content)
        content = re.sub('\\&\\#39\\;', '\'', content)
        content = re.sub('\\&\\#x3D\\;\\&gt\\;', '=>', content)
        content = re.sub('\\&\\#x60\\;', '`', content)

        # Write new file.
        f.seek(0)
        f.truncate()
        f.write(content)


routes_modules = []
for module in os.listdir(GENERATED_FILES_DIR):
    if not module.endswith('.erl'):
        continue

    routes_modules.append(module[:-4])
    fix_generated_routes_module(os.path.join(GENERATED_FILES_DIR, module))


rest_routes_module_content = """%%%--------------------------------------------------------------------
%%% This file has been automatically generated from Swagger
%%% specification - DO NOT EDIT!
%%%
%%% @copyright (C) 2019-2021 ACK CYFRONET AGH
%%% This software is released under the MIT license
%%% cited in 'LICENSE.txt'.
%%% @end
%%%--------------------------------------------------------------------
%%% @doc
%%% This module contains definitions of REST methods.
%%% @end
%%%--------------------------------------------------------------------
-module(rest_routes).

-include("http/rest.hrl").
-include("global_definitions.hrl").

-export([routes/0]).


%%%===================================================================
%%% API
%%%===================================================================


%%--------------------------------------------------------------------
%% @doc
%% Definitions of file REST paths.
%% @end
%%--------------------------------------------------------------------
-spec routes() -> [{Path :: binary(), Handler :: module(), RoutesForPath :: map()}].
routes() ->
    AllRoutes = lists:flatten([""" + ','.join('\n        {}:routes()'.format(module) 
                                              for module in sorted(routes_modules)) + """
    ]),

    SortedRoutes = sort_routes(AllRoutes),

    % Aggregate routes that share the same path
    AggregatedRoutes = lists:foldr(fun
        ({Path, Handler, #rest_req{method = Method} = RestReq}, [{Path, _, RoutesForPath} | Acc]) ->
            [{Path, Handler, RoutesForPath#{Method => RestReq}} | Acc];
        ({Path, Handler, #rest_req{method = Method} = RestReq}, Acc) ->
            [{Path, Handler, #{Method => RestReq}} | Acc]
    end, [], SortedRoutes),

    % Convert all routes to cowboy-compliant routes
    % - prepend REST prefix to every route
    % - rest handler module must be added as second element to the tuples
    % - RoutesForPath will serve as Opts to rest handler init.
    PrefixStr = op_worker:get_env(op_rest_api_prefix),
    Prefix = str_utils:to_binary(PrefixStr),
    lists:map(fun({Path, Handler, RoutesForPath}) ->
        {<<Prefix/binary, Path/binary>>, Handler, RoutesForPath}
    end, AggregatedRoutes).


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Sorts rest routes alphanumerically with accounting for fact that any concrete
%% path must precede path with match (e.g. `data/register` must precede `data/:id`).
%% Otherwise it would be impossible to make requests for such routes.
%% @end
%%--------------------------------------------------------------------
-spec sort_routes([{Path :: binary(), Handler :: module(), #rest_req{}}]) ->
    [{Path :: binary(), Handler :: module(), #rest_req{}}].
sort_routes(AllRoutes) ->
    % Replace ':' (ASCII 58) with `}` (ASCII 125) as this makes routes properly sortable
    AllRoutesWithSortingKey = lists:map(fun({Path, _Handler, _RestReq} = Entry) ->
        {binary:replace(Path, <<":">>, <<"}">>, [global]), Entry}
    end, AllRoutes),

    lists:map(fun({_Key, Entry}) -> Entry end, lists:sort(AllRoutesWithSortingKey)).
"""

with open('generated/cowboy/rest_routes.erl', 'w') as f:
    f.write(rest_routes_module_content)
