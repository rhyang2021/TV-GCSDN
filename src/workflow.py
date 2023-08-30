from src.game_master import GameMaster
from src.player_base import Player, players_to_chatbots, game_multithread
from typing import List
import gradio as gr

import time

enable_btn = gr.Button.update(interactive=True)
disable_btn = gr.Button.update(interactive=False)

def monitor_all(bidder_list):
    return sum([bidder.to_monitors() for bidder in bidder_list], [])

def run_game(game_master: GameMaster,
             player_list: List[Player],
             thread_num: int,
             yield_for_demo=True):

    chatbot_list = players_to_chatbots(player_list)

    if yield_for_demo:
        yield chatbot_list + monitor_all(player_list) + [game_master.all_game_history_to_string()] + [disable_btn, disable_btn]

    game_round = 0

    while not game_master.end_game():

        # remove the voted out players
        _player_list = []
        for player in player_list:
            if player.out:
                continue
            _player_list.append(player)

        # ***************** description session *****************
        for player in _player_list:

            game_history = game_master.all_game_history_to_string().replace(f"{player.name}", f"{player.name}(you)")
            # get belief
            belief_instruct = player.get_belief_instruct(game_history)
            player.belief(belief_instruct)
            # get deduce
            deduce_instruct = player.get_deduce_instruct()
            player.deduce(deduce_instruct)
            # get description
            describe_instruct = player.get_describe_instruct()
            msg = player.describe(describe_instruct)
            description = game_master.parse_describe(msg)
            game_master.record_game({'player': player.name, 'description': description}, game_round)

        chatbot_list = players_to_chatbots(player_list)

        if yield_for_demo:
            yield chatbot_list + monitor_all(player_list) + [game_master.all_game_history_to_string()] + [disable_btn, disable_btn]

        # ***************** voting session *****************
        # belief
        belief_instruct_list = []
        for player in _player_list:
            game_history = game_master.all_game_history_to_string().replace(f"{player.name}", f"{player.name}(you)")
            msg = player.get_belief_instruct(game_history)
            belief_instruct_list.append(msg)

        game_multithread(_player_list, belief_instruct_list, func_type='belief', thread_num=thread_num)
        chatbot_list = players_to_chatbots(player_list)
        if yield_for_demo:
            yield chatbot_list + monitor_all(player_list) + [game_master.all_game_history_to_string()] + [disable_btn, disable_btn]

        # deduce
        deduce_instruct_list = []
        for player in _player_list:
            msg = player.get_deduce_instruct()
            deduce_instruct_list.append(msg)

        game_multithread(_player_list, deduce_instruct_list, func_type='deduce', thread_num=thread_num)
        chatbot_list = players_to_chatbots(player_list)
        if yield_for_demo:
            yield chatbot_list + monitor_all(player_list) + [game_master.all_game_history_to_string()] + [disable_btn, disable_btn]

        # vote
        vote_instruct_list = []
        for player in _player_list:
            msg = player.get_vote_instruct()
            vote_instruct_list.append(msg)

        _msgs = game_multithread(_player_list, vote_instruct_list, func_type='vote', thread_num=thread_num)
        chatbot_list = players_to_chatbots(player_list)

        for player, msg in zip(_player_list, _msgs):
            voting = game_master.parse_vote(msg)
            game_master.record_game({'player': player.name, 'voting': voting}, game_round)

        if yield_for_demo:
            yield chatbot_list + monitor_all(player_list) + [game_master.all_game_history_to_string()] + [disable_btn, disable_btn]

        # ***************** judging *****************
        voted_player, is_spy = game_master.parse_spy(game_round)
        for player in _player_list:
            if player.name==voted_player:
                player.set_voteout()
        if is_spy:
            game_master.record_game({'player': voted_player, 'identity': 'spy, civilians win!'}, game_round)
        else:
            game_master.record_game({'player': voted_player, 'identity': 'not spy, is voted out, game continue!'}, game_round)

        if yield_for_demo:
            yield chatbot_list + monitor_all(player_list) + [game_master.all_game_history_to_string()] + [disable_btn, disable_btn]

        game_round += 1









