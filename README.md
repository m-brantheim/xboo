# xBoo autocompounder

1. Deposit Boo, get xBoo using enter(uint256 \_amount) public on BooMirrorWorld
2. Give approval, deposit xBoo using deposit(uint256 \_pid, uint256 \_amount) external on Acelab

# Compounding staked xBoo

1. Call pendingReward(uint256 \_pid, address \_user) on Acelab
2. Use the returned value to call withdraw(uint256 \_pid, uint256 \_amount) on Acelab for the amount parameter
   This will transfer all the available reward tokens and 0 xBoo (leaving it for more rewards)
3. Swap reward token -> Boo
4. Repeat steps 1 and 2 of depositing

Optional:
-When depositing in Acelab first pick the highest yield asset and use that pid to deposit

1. Loop through poolInfo
2. Get the RewardPerSecond value
3. Find the $ or Boo value of the token
4. Convert to rewards in that value, pick highest
