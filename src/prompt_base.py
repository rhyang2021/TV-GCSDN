SYSTEM_MESSAGE = """
You are {player_name}, who is attending an game "who is the spy". This game will have 4 other players with you.
Here is the basic information and rules.

Basic information:
- Players: player 1, 2, 3, 4, 5 (5 players in total)
- Your name: {player_name}
- The keyword you received: {player_identity}

Rules:
1. There are six players, randomly divided into two groups: 'Civilians' (4 players) and 'Spy' (1 player). There is only one player who get different keyword and is the spy in this game. Each civilian gets a 'keyword' similar yet distinct from the spy's keyword. You don't know your group identity or the keywords of others.

2. Each round has two sessions:
- Description session: Each player describes their assigned keyword using an adjective, avoiding the keyword itself or any word in it.
- Voting session: Players vote to eliminate one player. The one with the most votes is out of the game.

3. Winning Conditions:
- Civilians win if the spy is voted out.
- The spy wins if only two players remain, including the spy.
""".strip()

INSTRUCT_BELIEF_TEMPLATE  = """
As {player_name}, your keyword is {player_identity}.
Here is the game history:

{history_message}

---

Please deduce all 5 players' keywords according to the game history and then explain. Please output your deduction exactly in the following format:
- I am <your name>, my keyword is <your keyword>.
- Other players' keyword:
    - player name 1: <keyword 1/not sure>
        - Reason:
    - player name 2: <keyword 2/not sure>
        - Reason:
    - player name 3: <keyword 3/not sure>
        - Reason:
    - player name 4: <keyword 4/not sure>
        - Reason:

For each player, you should consider the following in the deduction process:
1. If this player's description does not exist in the game history, do not deduce the keyword of this player, answer not sure about his keyword and wait for more descriptions.
2. The majority should have a same keyword, only one player have different but similar keyword with others.
3. If this player has been voted out but not the spy, he must have the same keyword with the majority.
4. If you find it challenging to deduce this player's specific keyword, you can answer a general category the keyword might belong to.
""".strip()

INSTRUCT_DEDUCE_TEMPLATE = """
As {player_name}, your keyword is {player_identity}. Please deduce who the spy is, and then explain your reasoning. Please output your answers exactly in the following format:
- Who is the spy:
- Civilian's keyword:
- Spy's keyword:
- Reason:

For each player, you should consider the following in the deduction process:
1. You ({player_name}) are the spy if your keyword ({player_identity})differs from the majority deduced keywords of others.
2. If your keyword ({player_identity}) is the same as the majority of players, you ({player_name}) can deduce from one of the following perspectives:
- Remain uncertain about who the spy is and whether you are the spy.
- The player whose deduced keyword differs from most players or gives a contradictory description with your keyword might be the spy.
- The player who consistently provides ambiguous descriptions might be the spy.
- If a player is voted out but the game continues, that player cannot be the spy. The player who voted them out or provided contradictory descriptions with them might be the spy.
- The player who voted for a player whose deduced keyword is the same as the majority might be the spy.
""".strip()

INSTRUCT_DESCRIBE_TEMPLATE = """
Now the Game Master says:"{player_name}, It is your turn to give a desciption!"

As {player_name}, your keyword is {player_identity}. Your have to give a short description (less than 10 words) for your keyword and then explain it. Make sure your description is unique and must never be the same as someone else's.

Here are some common strategies to describe your keywords:
- If you are in Round 1, you should:
    - Give a general description in the first round to avoid revealing your identity or too much keyword features too early, do not give contradictory descriptions with others. For example, if your keyword is <apple>, you can descibe it as <It is sweet> or <It is a kind of fruit>.

- If you are in the following rounds:
    - If you deduce you are the spy:
        - Do not give descriptions that contradict the features given by civilians. For example, if your keyword is <duck> and civilian's keywords are <chicken>, you should never describe your keyword as <it can swim>.
        - Deduce the civilians' keywords and be as close to their keywords as possible to prevent them from guessing your keyword.
        - Stick to the features of the keyword you received; do not deviate from it.

    - If you deduce you are a civilian (not the spy):
        - Deduce the spy's keywords and imply that you are a civilian to other civilians through your description.
        - Prevent the spy from guessing your actual keyword.

    - If you are not sure about your identity:
        - Give a general description that does not contradict other players' descriptions to avoid giving away your keyword and identity too early.
""".strip()

INSTRUCT_VOTE_TEMPLATE = """
Now the Game Master says:"{player_name}, It is your turn to vote!"
As {player_name}, your keyword is {player_identity}. Your have to cast your vote by saying "I vote for player X", and then explain.

Here are some common strategies to consider while voting:
- If you think you are the spy, you should vote for the civilian who has the most ambiguous description to divert the civilians' attention from yourself.
- If you think you are a civilian, you should identify the player who provided a description that doesn't match your keyword, and vote for them.
- If you are not sure about your identity, you should vote for the player who gives the most ambiguous description.

Note that you should not vote for yourself or the player who has already been voted out!
""".strip()

PARSE_BELIEF_SYSTEM_INSTRUCTION = """
Your task is to provide a JSON object from the given text that represent the deduced keyword for each player(5 players in total). Here is the format:
- The keyword for each player listed as key-value pairs, for example, {"player_name_1": "key_word_1" , "player_name_2": "key_word_2",...}.
- The answer should be in order of player 1, 2, 3, 4, 5

For example, the given text is:

'''
- I am player 3, my keyword is mango.
- Other players' keyword:
    - player 1: duck 
    - player 2: a kind of fruit
    - player 4: a kind of vegetable
    - player 5: not sure
'''

Then, the JSON object should strictly follow this format and structure:

{"player 1": "duck", "player 2": "a kind of fruit", "player 3": "mango", "player 4": "a kind of vegetable", "player 5": "not sure"}
""".strip()

PARSE_DESCRIBE_INSTRUCTION = """
Please extract from the given text the description. Here is the text:

{response}

Don't say anything else other than just a sentence, e.g., "It is a sweet fruit".
""".strip()

PARSE_VOTE_INSTRUCTION = """
Please extract from the given text the voted player. Here is the text:

{response}

Don't say anything else other than just a player's name, e.g., "player 4".
""".strip()

PARSE_SPY_INSTRUCTION = """
Please extract from the given text the player with the most votes. Here is the text:

{response}

Don't say anything else other than just a player's name, e.g., "player 4".
""".strip()