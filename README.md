# Retail Fuel Price Prediction

Retail fuel prices have gained traction among consumers who are struggling with rising cost of living recently. Precise forecasting of fuel prices therefore will benefit the general population, helping them manage personal finance more actively and effectively.
With numerous forecasting techniques at hand, it's quite straightforward to implement multiple financial models and choose the best one that suits one's needs. Prior to a technical solution, it's of utmost importance to understand the characteristics of the oil retailer industry in a particular market, which in this case is New South Wales (NSW), the largest state of Australia.
Obviously, retail fuel price is influenced by crude oil price. Moreover, the consumer prices are not identical across retailers and even different among branches of a single retailer. That is attributed to demographic features like population density, distance to fuel distributor, commuting preference by residents, etc. To make reliable accurate predictions, those factors need to be incorporated into the models.
One critical issue faced by the models is the different frequency of data update between fuel prices and demographic features. While fuel prices vary across days (or even across points of time during a day), other data can only be released by year. To address this unmatch, a clustering technique is employed, grouping 29 regions of NSW into a few clusters of similar demography and price movement patterns.
Key findings of this approach:
- The retail prices across locations were driven by the Terminal Gate Prices (TGPs), the wholesale prices by refineries.
- Metropolitan and its neughbouring suburbs (yellow and green lines in the figure) experienced repetitve price cycles across time. This indicated a tough competitve environment in the region in which retailers executed markdown tactics to lure consumers and to compete with their rivals, then prices rebounded after price promotions.
- In areas farther away from the metropolis, less severe competition, lack of public transport, and low density of population altogether led the consumer prices flatter despite multiple ups and downs.

![image](https://github.com/user-attachments/assets/cd3acead-15b6-429c-a91e-dd08f832c676)

The more transparent pattern of prices in urban areas also produced more reliable forecasts.

![image](https://github.com/user-attachments/assets/13bdcb9e-9517-4ac4-8b3f-9ba4854bd5f5)

![image](https://github.com/user-attachments/assets/45cc8a86-dc26-43dd-a185-08199178fd40)

