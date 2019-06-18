#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re


GENERATED_FILES_DIR = 'generated/cowboy'
PATHS_INDEX_FILE = 'paths/index.yaml'

OPERATIONS_RE = re.compile(r'(?<=(\[|,)\n)'
                           r'(?P<operation>\s+%%.+?\{<<"(?P<path>.+?)">>.+?\},?\n)'
                           r'(?=\s*(%%|\]))', flags=re.DOTALL)

REST_API_RE = re.compile(r'^(?P<header>.*?\[\n).*\n(?P<footer>\s*]\..*)$',
                         flags=re.DOTALL)


with open(PATHS_INDEX_FILE, "r") as f:
    ordered_paths = [re.sub(r'{(.*?)}', ':\g<1>', line.rstrip(':\n'))
                     for line in f
                     if line.startswith('/') and line.endswith(':\n')]


for n in os.listdir(GENERATED_FILES_DIR):
    if n.startswith('.'):
        continue
    with open(os.path.join(GENERATED_FILES_DIR, n), "r+") as f:
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
        lines = ''.join(new_lines)

        # Fix paths ordering
        header, footer = REST_API_RE.match(lines).groups()
        rest_routes = {}
        for rest_route in OPERATIONS_RE.finditer(lines):
            path = rest_route.group('path')
            operation = rest_route.group('operation')
            try:
                val = rest_routes[path]
            except KeyError:
                rest_routes[path] = operation.replace(':path">>', '[...]">>')
            else:
                rest_routes[path] = val + operation.replace(':path">>', '[...]">>')
        else:
            operations = ''.join(rest_routes[path]
                                 for path in ordered_paths
                                 if path in rest_routes)
            lines = header + operations + footer

        # Fix syntax and substitute invalid character sequences.
        lines = re.sub(r',(\s*[}\]\)])', '\g<1>', lines)
        lines = re.sub('\\&\\#39\\;', '\'', lines)
        lines = re.sub('\\&\\#x3D\\;\\&gt\\;', '=>', lines)
        lines = re.sub('\\&\\#x60\\;', '`', lines)

        # Write new file.
        f.seek(0)
        f.truncate()
        f.write(lines)
