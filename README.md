# Agent-based stock market modelling and simulation 

## About the project 

This project aims to investigate how varying degrees of information asymmetry leads to market volatility and wealth inequality. Specifically, the following market dynamics will be explored: trader sensitivity to news, and trader exposure to private information in different network topologies. By varying these dynamics and assessing the conditions conducive to volatility, it is anticipated that further understanding into stock market volatility will be generated.

* How is the market shaped by traders predisposed to different psychological tendencies? 
* What are network structures conducive to volatility in the market and unequal wealth distribution? 

  For extension of the research questions, wealthy stock market participants will be analysed in an attempt to understand the strategies with a tendency to produce a successful outcome.
  
<br>

## Model design

The basic principle of the model is the concept of psychological tendencies: agents make an investment decision based on their reaction towards public information and neighbours’ opinion. The objective of agents is to increase their total assets, which includes their cash balance and the market value of their shares. However, the agents do not calculate the expected return, but rather implicitly predict it based on the sentiments. For instance, if the perceived sentiment is positive, agents expect a price rise and buy more shares. 

Agents have full knowledge of the market state and news, and partial information of other agents (an agent only senses the sentiment of agents it is directly connected to), and this knowledge is used to make trade decisions. The model does not implement learning or prediction - agents follow the simplified rules throughout simulations. Agents interact both directly - through trading and communication of sentiment - and indirectly - through affecting the price of shares by making buy andsell orders on the market. Stochasticity is used to initialise the state of the market and the agents. It is also used to model subprocesses. There are no collectives in this model. The market as a whole exhibits emergent and non-trivial patterns, resulting from agents following simple rules. Standard deviation of quarterly stock price, Gini coefficient and the final net worth of agents are tracked to observe the system behaviour.

<br>

## Experiments

* Experiment1: The main objective of this experiment is to understand the effect of private (influencer) sentiment on stock market volatility. In order to measure the volatility, standard deviation of stock prices for the final 90 days is used
as an indicator. 
* Experiment2: In the second experiment, the purpose is to investigate the relationship between volatility and network topology in the absence of global news. With parameters maximising the impact of local sentiment (peer-sens and infl-sens), the simulation is run 50 times per topology. In addition to the standard deviation and Gini index described in experiment 1, the final networth distribution of traders is captured for wealth distribution analysis under the various network conditions. 
* Experiment3: As an extension of the previous experiments, the common patterns of big winners are captured. In this experiment, simulations are run with parameters which can maximize the number of traders who winconsistently over the time period of a single simulation.  For the diversity in agents’ trading strategies, wider deviation is applied.


I used Python for data analysis.<br>
Results Experiment1 and Experiment2 are analysed in `exp1 and exp2.ipynb`.<br>
Results from Experiment3 are analysed in `exp3.ipynb`.

<br>

## How to run
Either download NetLogo or use web version NetLogo at https://ccl.northwestern.edu/netlogo/. To view the user-friendly interface, I suggest to download NetLogo and open `stock model.nlogo`. The user interface may be too simplified in the web version.
<br>

You can play around with various parameter settings and export the results for further analysis. 

<br>

## Version
NetLogo 6.2.2. 

<br>

----

:newspaper: :+1: <br>
:ear: :mega: :lips: :speech_balloon: <br>
:chart_with_upwards_trend: :chart_with_downwards_trend:<br>

Have fun 😉
