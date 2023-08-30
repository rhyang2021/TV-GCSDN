import threading
from typing import List
from langchain.prompts import PromptTemplate
from langchain.base_language import BaseLanguageModel
from langchain.schema import (
    AIMessage,
    HumanMessage,
    SystemMessage
)
from langchain.chat_models import (
    ChatAnthropic,
    ChatOpenAI,
    ChatVertexAI
)
from langchain.input import get_colored_text
from langchain.callbacks import get_openai_callback
from pydantic import BaseModel
import queue
import re
import ujson as json
import matplotlib.pyplot as plt

from src.prompt_base import (
    SYSTEM_MESSAGE,
    INSTRUCT_BELIEF_TEMPLATE,
    INSTRUCT_DEDUCE_TEMPLATE,
    INSTRUCT_DESCRIBE_TEMPLATE,
    INSTRUCT_VOTE_TEMPLATE,
    PARSE_BELIEF_SYSTEM_INSTRUCTION,
)

import sys
sys.path.append('..')

class Player(BaseModel):
    name: str
    model_name: str
    identity: str

    llm: BaseLanguageModel = None
    temperature: float = 0.7
    openai_cost = 0
    llm_token_count = 0
    out: bool = False

    verbose: bool = False

    system_message: str = ''

    # working memory
    cur_round: int = 0
    cur_session: int = 0
    cur_belief: list = []
    cur_spy: str = ''
    cur_spy_keyword: str = ''
    cur_civilian_keyword: str = ''
    dialogue_history: list = []
    message_history: list = []

    # belief tracking
    belief_history: list = [] #[[cur_belief],[player 1: xx, player 2: xx]]
    deduction_history: list = []
    deduction_correct_history: list = []
    spy_keyword_correct_history: list = []
    civilian_keyword_correct_history: list = []

    @classmethod
    def create(cls, **data):
        instance = cls(**data)
        instance._post_init_()
        return instance

    def _post_init_(self):

        self.system_message = SYSTEM_MESSAGE.format(
            player_name=self.name,
            player_identity=self.identity,
        )
        self._parse_llm()
        self.dialogue_history.append(SystemMessage(content=self.system_message))

    def _parse_llm(self):
        if 'gpt-' in self.model_name:
            self.llm = ChatOpenAI(model=self.model_name, temperature=self.temperature)
        elif 'claude' in self.model_name:
            self.llm = ChatAnthropic(model=self.model_name, temperature=self.temperature)
        elif 'bison' in self.model_name:
            import vertexai
            vertexai.init(project="ai2-aristo", location="us-central1")
            self.llm = ChatVertexAI(model=self.model_name, temperature=self.temperature)
        else:
            raise NotImplementedError(self.model_name)

    def _run_llm_standalone(self, messages: list):
        with get_openai_callback() as cb:
            input_token_num = self.llm.get_num_tokens_from_messages(messages)
            if 'claude' in self.model_name:     # anthropic's claude
                result = self.llm(messages, max_tokens_to_sample=2048)
            elif 'bison' in self.model_name:    # google's palm-2
                max_tokens = max(4000 - input_token_num, 96)
                result = self.llm(messages, max_output_tokens=min(max_tokens, 1024))
            else:                               # openai
                if 'gpt-3.5-turbo' in self.model_name and '16k' not in self.model_name:
                    max_tokens = max(3900 - input_token_num, 192)
                else:
                    max_tokens = max(8000 - input_token_num, 192)
                result = self.llm(messages, max_tokens=max_tokens)
            self.openai_cost += cb.total_cost
            self.llm_token_count = self.llm.get_num_tokens_from_messages(messages)
        return result.content

    # ********** Main Instructions and Functions ********** #

    def get_belief_instruct(self, text: str):

        belief_instruct = INSTRUCT_BELIEF_TEMPLATE.format(
            history_message=text,
            player_name=self.name,
            player_identity=self.identity,
        )
        return belief_instruct


    def belief(self, belief_instruct: str):

        belief_msg = HumanMessage(content=belief_instruct)
        msgs = [SystemMessage(content=self.system_message)]
        self.message_history += [belief_msg]
        msgs += self.message_history

        result = self._run_llm_standalone(msgs)

        self.message_history.append(AIMessage(content=result))

        self.dialogue_history += [
            belief_msg,
            AIMessage(content=result)
        ]

        # update belief
        self.cur_belief = self._parse_belief(result)
        if self.cur_session % 2 == 0:
            self.belief_history.append([f"{self.cur_round} (description)"] + self.cur_belief)
        else:
            self.belief_history.append([f"{self.cur_round} (voting)"] + self.cur_belief)

        if self.verbose:
            print(get_colored_text(belief_instruct, 'yellow'))
            print(get_colored_text(result, 'green'))

        return result


    def get_deduce_instruct(self):

        deduce_instruct = INSTRUCT_DEDUCE_TEMPLATE.format(
            player_name=self.name,
            player_identity=self.identity,
        )
        return deduce_instruct

    def deduce(self, deduce_instruct: str):

        deduce_msg = HumanMessage(content=deduce_instruct)
        msgs = [SystemMessage(content=self.system_message)]
        self.message_history += [deduce_msg]
        msgs += self.message_history

        deduction = self._run_llm_standalone(msgs)

        self.message_history.append(AIMessage(content=deduction))

        self.dialogue_history += [
            deduce_msg,
            AIMessage(content=deduction)
        ]

        # update deduction
        self._parse_deduce(deduction)
        if self.cur_session % 2 == 0:
            self.deduction_history.append([f"{self.cur_round} (description)", self.cur_spy, self.cur_spy_keyword, self.cur_civilian_keyword])
        else:
            self.deduction_history.append([f"{self.cur_round} (voting)", self.cur_spy, self.cur_spy_keyword, self.cur_civilian_keyword])

        self.deduction_correct_history.append(1) if self.cur_spy=='player D' else self.deduction_correct_history.append(0)
        self.spy_keyword_correct_history.append(1) if self.cur_spy_keyword == 'duck' else self.spy_keyword_correct_history.append(0)
        self.civilian_keyword_correct_history.append(1) if self.cur_spy_keyword == 'chicken' else self.civilian_keyword_correct_history.append(0)

        # update session
        self.cur_session += 1

        return deduction

    def get_describe_instruct(self):

        describe_instruct = INSTRUCT_DESCRIBE_TEMPLATE.format(
            player_name=self.name,
            player_identity=self.identity,
        )
        return describe_instruct

    def describe(self, describe_instruct: str):

        describe_msg = HumanMessage(content=describe_instruct)
        msgs = [SystemMessage(content=self.system_message)]
        self.message_history += [describe_msg]
        msgs += self.message_history

        description = self._run_llm_standalone(msgs)

        self.message_history.append(AIMessage(content=description))

        self.dialogue_history += [
            describe_msg,
            AIMessage(content=description)
        ]

        return description


    def get_vote_instruct(self):

        vote_instruct = INSTRUCT_VOTE_TEMPLATE.format(
            player_name=self.name,
            player_identity=self.identity,
        )
        return vote_instruct

    def vote(self, vote_instruct: str):

        vote_msg = HumanMessage(content=vote_instruct)
        msgs = [SystemMessage(content=self.system_message)]
        self.message_history += [vote_msg]
        msgs += self.message_history

        voting = self._run_llm_standalone(msgs)

        self.message_history.append(AIMessage(content=voting))

        self.dialogue_history += [
            vote_msg,
            AIMessage(content=voting)
        ]

        # move on to next round
        self.cur_round += 1
        return voting

    def set_voteout(self):
        self.out = True

    # *********** Belief Tracking *********** #

    def _parse_belief(self, text: str):
        '''
        with get_openai_callback() as cb:
            llm = ChatOpenAI(model='gpt-3.5-turbo-0613', temperature=0.)
            result = llm([SystemMessage(content=PARSE_BELIEF_SYSTEM_INSTRUCTION),
                          HumanMessage(content=f"{text}\nDon't output anything else other than the JSON object.")])
            self.openai_cost += cb.total_cost

        belief_json = json.loads(result.content)
        '''
        player_keyword_matches = re.findall(r"player (\d+): ([^\n]+)", text)
        player_keywords_dict = {'player ' + player: keyword for player, keyword in player_keyword_matches}
        player_keywords_dict[self.name] = self.identity
        belief_json = dict(sorted(player_keywords_dict.items(), key=lambda item: int(item[0].split()[1])))

        return list(belief_json.values())


    def _parse_deduce(self, text: str):
        # extract "who is the spy"
        who_is_spy_match = re.search(r"Who is the spy: ([^\n]+)", text)
        if who_is_spy_match:
            self.cur_spy = who_is_spy_match.group(1)

        # Extract "Spy's keyword"
        spy_keyword_match = re.search(r"Spy's keyword: ([^\n]+)", text)
        if spy_keyword_match:
            self.cur_spy_keyword = spy_keyword_match.group(1)

        # Extract "Civilians' keyword"
        civilians_keyword_match = re.search(r"Civilian's keyword: ([^\n]+)", text)
        if civilians_keyword_match:
            self.cur_civilian_keyword = civilians_keyword_match.group(1)

    # ****************** Logging ****************** #

    def to_monitors(self):
        # tokens, cost, belief_history, deduction history
        belief_history = self.belief_history if self.belief_history != [] else [['', '', '']]
        deduction_history = self.deduction_history if self.deduction_history != [] else [['', '', '']]

        return [self.llm_token_count, round(self.openai_cost, 2),
                belief_history,
                deduction_history,
                draw_plot(f"{self.name} ({self.model_name})", self.deduction_correct_history,
                          self.spy_keyword_correct_history, self.civilian_keyword_correct_history),
                ]

    def dialogue_to_chatbot(self):
        # chatbot: [[Human, AI], [], ...]
        # only dialogue will be sent to LLMs. chatbot is just for display.
        chatbot = [[self.dialogue_history[0].content, 'Got it!']]
        dialogue = self.dialogue_history.copy()[1:] # excluding system message
        for i in range(0, len(dialogue), 2):
            # if exceeds the length of dialogue, append the last message
            if i+1 >= len(dialogue):
                ai_msg = None
            else:
                ai_msg = dialogue[i+1].content
            chatbot.append([dialogue[i].content, ai_msg])
        return chatbot


def game_multithread(player_list: List[Player],
                        instruction_list,
                        func_type,
                        thread_num=5):
    '''
    auctioneer_msg: either a uniform message (str) or customed (list)
    '''
    assert func_type in ['describe', 'vote', 'belief', 'deduce']
    # 多线程
    result_queue = queue.Queue()
    threads = []
    semaphore = threading.Semaphore(thread_num)

    def run_once(i: int, player: Player, game_master_msg: str):
        try:
            semaphore.acquire()
            if func_type == 'describe':
                result = player.describe(game_master_msg)
            elif func_type == 'vote':
                result = player.vote(game_master_msg)
            elif func_type == 'belief':
                result = player.belief(game_master_msg)
            elif func_type == 'deduce':
                result = player.deduce(game_master_msg)
            else:
                raise NotImplementedError(f'func_type {func_type} not implemented')
            result_queue.put((i, result))
        finally:
            semaphore.release()

    if isinstance(instruction_list, str):
        instruction_list = [instruction_list] * len(player_list)

    for i, (player, msg) in enumerate(zip(player_list, instruction_list)):
        thread = threading.Thread(target=run_once, args=(i, player, msg))
        thread.start()
        threads.append(thread)

    for thread in threads:
        thread.join()

    results = [result_queue.get() for _ in range(len(player_list))]
    results.sort()
    return [x for _, x in results]


def draw_plot(title, deduction_list, spy_list, civilian_list):

    fig, ax1 = plt.subplots()

    ax1.plot(deduction_list, label='Spy identity')
    ax1.plot(spy_list, label='Spy keyword')
    ax1.plot(civilian_list, label='Civilian keyword')

    ax1.set_title(title)
    ax1.set_xlabel('Game Rounds')
    ax1.set_ylabel('True or False')
    ax1.set_yticks([0, 1])
    ax1.set_xticks(range(len(deduction_list)))

    ax1.legend()

    return fig


def players_to_chatbots(player_list: List[Player], profit_report=False):

    return [x.dialogue_to_chatbot() for x in player_list]
