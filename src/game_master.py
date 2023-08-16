import re
from typing import List, Dict
from langchain.prompts import PromptTemplate
from langchain.chat_models import ChatOpenAI
from langchain.callbacks import get_openai_callback
from langchain.schema import (
    AIMessage,
    HumanMessage,
    SystemMessage
)
from collections import defaultdict
import random
from src.prompt_base import (
    PARSE_DESCRIBE_INSTRUCTION,
    PARSE_VOTE_INSTRUCTION,
    PARSE_SPY_INSTRUCTION
)
from pydantic import BaseModel

class GameMaster(BaseModel):

    player_num: int = 5
    spy: str
    openai_cost = 0

    game_history = defaultdict(list)
    voted_player: str = ''

    @classmethod
    def create(cls, **data):
        instance = cls(**data)
        return instance

    def record_game(self, game_info: dict, game_round: int):
        '''
        Save the bidding history for each round, log the highest bidder and highest bidding
        '''
        # bid_info: {'bidder': xxx, 'bid': xxx, 'raw_msg': xxx}
        self.game_history[game_round].append(game_info)
        # self.auction_logs[f"{self.cur_item.get_desc()}"].append(
            # {'bidder': bid_info['bidder'],
             # 'bid': bid_info['bid'],
             # 'bid_round': bid_round})


    def _history_to_string(self, game_round: int):
        '''
        Return a string that summarizes the bidding history in a round
        '''
        # bid_hist_text = '' if bid_round == 0 else f'- {self.highest_bidder}: ${self.highest_bid}\n'
        game_hist_text = ''
        for js in self.game_history[game_round]:
            if 'description' in js:
                game_hist_text += f"- {js['player']}: {js['description']}\n"
            elif 'voting' in js:
                game_hist_text += f"- {js['player']} vote for {js['voting']}\n"
            else:
                game_hist_text += f"- {js['player']} has the most votes, is {js['identity']}\n"
        return game_hist_text.strip()

    def all_game_history_to_string(self):
        game_hist_text = ''
        for game_round in self.game_history:
            game_hist_text += f"Round {game_round}:\n{self._history_to_string(game_round)}\n\n"
        return game_hist_text.strip()


    def ask_for_describe(self, bid_round: int):
        '''
        Ask for description, return the message to be sent to bidders
        '''
        return 0

    def end_game(self):
        return self.player_num<=2 or self.voted_player == self.spy

    def parse_describe(self, text: str):
        prompt = PARSE_DESCRIBE_INSTRUCTION.format(response=text)
        with get_openai_callback() as cb:
            llm = ChatOpenAI(model='gpt-3.5-turbo-0613', temperature=0)
            result = llm([HumanMessage(content=prompt)]).content
            self.openai_cost += cb.total_cost

        return result

    def parse_vote(self, text: str):
        prompt = PARSE_VOTE_INSTRUCTION.format(response=text)
        with get_openai_callback() as cb:
            llm = ChatOpenAI(model='gpt-3.5-turbo-0613', temperature=0)
            result = llm([HumanMessage(content=prompt)]).content
            self.openai_cost += cb.total_cost

        return result

    def parse_spy(self, game_round: int):
        prompt = PARSE_SPY_INSTRUCTION.format(response=self._history_to_string(game_round))
        with get_openai_callback() as cb:
            llm = ChatOpenAI(model='gpt-3.5-turbo-0613', temperature=0)
            result = llm([HumanMessage(content=prompt)]).content.replace('P', 'p')
            self.openai_cost += cb.total_cost

        self.voted_player = result
        self.player_num -= 1
        is_spy = result==self.spy

        return result, is_spy


