import os
import ujson as json
import time
import gradio as gr
from src.game_master import GameMaster
from src.player_base import Player
from src.workflow import run_game
from app_modules.presets import *
from app_modules.overwrites import *
from app_modules.utils import *
from utils import chunks, reset_state_list


LOG_DIR = 'logs'
PLAYER_NUM = 5
name_list = ['Player 1','Player 2','Player 3', 'Player 4', 'Player 5']
identity_list = ['mango', 'pineapple']

def game_loop(*args):
    spy_id = args[0][0]
    os.environ['OPENAI_API_KEY'] = args[1] if args[1] != '' else os.environ.get('OPENAI_API_KEY', '')
    os.environ['ANTHROPIC_API_KEY'] = args[2] if args[2] != '' else os.environ.get('ANTHROPIC_API_KEY', '')
    thread_num = args[3]
    args = args[4:]
    game_hash = str(int(time.time()))

    game_master = GameMaster.create(**{'spy': name_list[spy_id].replace('P', 'p')})

    # must correspond to the order in app's parameters
    input_keys = [
        'chatbot', 
        'model_name', 
        'temperature',
    ]
    
    # convert flatten list into a json list
    input_jsl = []
    for i, chunk in enumerate(chunks(args, len(input_keys))):
        js = {'name': f"player {i+1}", 'game_hash': game_hash, 'identity': identity_list[0]} if i==spy_id else {'name': f"player {i+1}", 'game_hash': game_hash, 'identity': identity_list[1]}
        for k, v in zip(input_keys, chunk):
            js[k] = v
        input_jsl.append(js)
    
    player_list = []
    for js in input_jsl:
        js.pop('chatbot')
        player_list.append(Player.create(**js))
    
    yield from run_game(game_master, player_list, thread_num, yield_for_demo=True)
    # log_players(game_hash, player_list)


with open("assets/custom.css", "r", encoding="utf-8") as f:
    customCSS = f.read()

with gr.Blocks(css=customCSS, theme=small_and_beautiful_theme) as demo:
    
    enable_btn = gr.Button.update(interactive=True)
    disable_btn = gr.Button.update(interactive=False)
    no_change_btn = gr.Button.update()

    with gr.Row():
        gr.HTML(title)

    gr.Markdown(description_top)

    with gr.Row():

        spy_checkbox = gr.CheckboxGroup(
            choices=[player_name for player_name in name_list],
            label="Players in game",
            info="Select one player to be spy in this game.",
            value='Player 3',
            type="index",
        )
        thread_num = gr.Slider(
            minimum=1,
            maximum=PLAYER_NUM,
            value=min(5, PLAYER_NUM),
            step=1,
            interactive=True,
            label='Thread Number',
            info="More threads, faster bidding, but will run into RateLimitError quicker."
        )
    with gr.Row():
        openai_key = gr.Textbox(label="OpenAI API Key", value="", type="password", placeholder="sk-..")
        anthropic_key = gr.Textbox(label="Anthropic API Key", value="", type="password", placeholder="sk-ant-..")


    with gr.Row():
        player_info_gr = []
        chatbots = []
        monitors = []
        for i in range(PLAYER_NUM):
            with gr.Tab(label=f"Player {i+1}"):
                with gr.Row().style(equal_height=True):
                    with gr.Column(scale=6):
                        with gr.Row():
                            chatbot = gr.Chatbot(elem_id="chuanhu_chatbot", height=800, label='Auction Log')
                        chatbots.append(chatbot)
                    with gr.Column(scale=4):
                        with gr.Tab(label=f'Parameters'):
                            model_name = gr.Dropdown(
                                choices=[
                                    'gpt-3.5-turbo-0613',
                                    'gpt-3.5-turbo-16k-0613', 
                                    'gpt-4-0613',
                                    'claude-instant-1.1',
                                    'claude-1.3',
                                    'claude-2.0',
                                    # 'chat-bison@001'
                                ], 
                                value='gpt-3.5-turbo-16k-0613',
                                label="Model Selection",
                            )
                            temperature = gr.Slider(
                                minimum=0.,
                                maximum=2.0,
                                value=0.1,
                                step=0.1,
                                interactive=True,
                                label="Temperature",
                            )

                        with gr.Tab(label='Monitors'):
                            with gr.Row():
                                tokens_monitor = gr.Number(
                                    label='Token Used', 
                                    interactive=False, 
                                    info='Tokens used in the last call.'
                                )
                                money_monitor = gr.Number(
                                    label='API Cost ($)', 
                                    info='Only OpenAI cost for now.',
                                    interactive=False
                                )
                            belief_change_monitor = gr.DataFrame(
                                label='Belief Changes',
                                headers=['Round', 'Player 1', 'Player 2', 'Player 3', 'Player 4', 'Player 5'],
                                datatype=['str', 'str', 'str', 'str', 'str', 'str'],
                                interactive=False,
                            )
                            deduction_change_monitor = gr.DataFrame(
                                label='Deduction Changes',
                                headers=['Round', 'Who is the Spy', 'Spy\'s keyword', 'Civilian\'s keyword'],
                                datatype=['str', 'str', 'str', 'str'],
                                interactive=False,
                            )
                            plot_monitor = gr.Plot(
                                label='Deduction Plot',
                                interactive=False
                            )

                        monitors += [
                            tokens_monitor, 
                            money_monitor,
                            belief_change_monitor,
                            deduction_change_monitor,
                            plot_monitor,
                        ]

                player_info_gr += [
                    chatbot,
                    model_name,
                    temperature,
                ]
    
    with gr.Row():
        with gr.Column():
            startBtn = gr.Button('Start', variant='primary', interactive=True)
        with gr.Column():
            clearBtn = gr.Button('New Game', variant='secondary', interactive=False)
        btn_list = [startBtn, clearBtn]
    
    with gr.Accordion(label='Game Log (click to open)', open=True):
        with gr.Row():
            game_log = gr.Markdown(value="")

    gr.Markdown(description)

    start_args = dict(
        fn=game_loop,
        inputs=[spy_checkbox, openai_key, anthropic_key, thread_num] + player_info_gr,
        outputs=chatbots + monitors + [game_log] + btn_list,
        show_progress=True,
    )
    
    start_event = startBtn.click(**start_args)

    clearBtn.click(reset_state_list, 
                   inputs=chatbots + monitors + [game_log], 
                   outputs=chatbots + monitors + [game_log], 
                   show_progress=True).then(lambda: enable_btn, outputs=[startBtn])
    
    demo.title = 'Who is the Spy?'


demo.queue(concurrency_count=3).launch(
    server_name='0.0.0.0',
    ssl_verify=False,
    share=True, 
    debug=True,
    show_api=False,
)

demo.close()