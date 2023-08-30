import ujson as json


def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i : i + n]


def reset_state_list(*states):
    empty = [None for _ in states]
    return empty


def LoadJsonL(filename):
    if isinstance(filename, str):
        jsl = []
        with open(filename) as f:
            for line in f:
                jsl.append(json.loads(line))
        return jsl
    else:
        return filename