# This is a helper script to see if a given config file is included in another config file.
# so that all config values are present in the other config file
import sys
from pprint import pprint
import json

with open(sys.argv[1]) as data_file:
    first = json.load(data_file)

with open(sys.argv[2]) as data_file:
    second = json.load(data_file)


def check_contains(lhs, rhs):
    """
    Checks if lhs contains all pair ofs kes and values provided in lhs.
    """
    if isinstance(rhs, dict):
        valid = True
        for key, value in rhs.iteritems():
            if key in lhs:
                valid &= check_contains(lhs[key], rhs[key])
            else:
                return False
        return valid
    elif isinstance(rhs, list):
        return all(x in lhs for x in rhs)
    else:
        return lhs == rhs
    return True

if check_contains(first, second):
    # if the config is included -> success
    sys.exit(0)
else:
    # if the config is not completly included -> failure
    sys.exit(1)
