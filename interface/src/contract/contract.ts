import { getContract, erc20Abi } from 'viem';

import { getWalletClient } from '@wagmi/core';
import { config } from '@/config/wagmi';
import SuperStrategyABI from './abi/QuantQueen.json';
export async function getERC20Contract(address: `0x${string}`) {
  const walletClient = await getWalletClient(config);
  if (!walletClient) throw new Error('Wallet client not available');

  return getContract({
    abi: erc20Abi,
    address,
    client: walletClient,
  });
}





export async function getSuperStrategyContract(address: `0x${string}`) {
  const walletClient = await getWalletClient(config);
  if (!walletClient) throw new Error('Wallet client not available');

  return getContract({
    abi: SuperStrategyABI,
    address,
    client: walletClient,
  });
}

