# Agent-based stock market modelling and simulation 

## About the project 

This project aims to investigate how varying degrees of information asymmetry leads to market volatility and wealth inequality. Specifically, the following market dynamics will be explored: trader sensitivity to news, and trader exposure to private information in different network topologies. By varying these dynamics and assessing the conditions conducive to volatility, it is anticipated that further understanding into stock market volatility will be generated.

1. How is the market shaped by traders predisposed to different psychological tendencies? 
2. What are network structures conducive to volatility in the market and unequal wealth distribution? 

  For extension of the research questions, wealthy stock market participants will be analysed in an attempt to understand the strategies with a tendency to produce a successful outcome.
<br>

## Experimental Design

The basic principle of the model is the concept of psychological tendencies: agents make an investment decision based on their reaction towards public information and neighbours’ opinion. The objective of agents is to increase their total assets, which includes their cash balance and the market value of their shares. However, the agents do not calculate the expected return, but rather implicitly predict it based on the sentiments. For instance, if the perceived sentiment is positive, agents expect a price rise and buy more shares. 

Agents have full knowledge of the market state and news, and partial information of other agents (an agent only senses the sentiment of agents it is directly connected to), and this knowledge is used to make trade decisions. The model does not implement learning or prediction - agents follow the simplified rules throughout simulations. Agents interact both directly - through trading and communication of sentiment - and indirectly - through affecting the price of shares by making buy andsell orders on the market. Stochasticity is used to initialise the state of the market and the agents. It is also used to model subprocesses. There are no collectives in this model. The market as a whole exhibits emergent and non-trivial patterns, resulting from agents following simple rules. Standard deviation of quarterly stock price, Gini coefficient and the final net worth of agents are tracked to observe the system behaviour.
<br>

## How to run
Either download NetLogo or use web version NetLogo at https://ccl.northwestern.edu/netlogo/. For a brief look, I suggest to use the web version NetLogo by uploading `stock model.nlogo`. The user interface differs in the web version. NetLogo 6.2.2. 
<br>

----

:newspaper: :+1: 

:ear: :mega: :lips: :speech_balloon:

:chart_with_upwards_trend: :chart_with_downwards_trend:


Have fun 😉
