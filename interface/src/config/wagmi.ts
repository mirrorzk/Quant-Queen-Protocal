import {
  arbitrum,
  base,
  bsc,
  holesky,
  mainnet,
  optimism,
  polygon,
  avalanche,
  hoodi
} from 'wagmi/chains';
import { createConfig, http } from 'wagmi';
import { connectorsForWallets } from '@rainbow-me/rainbowkit';
import {
  walletConnectWallet,
  metaMaskWallet,
  rabbyWallet,
  okxWallet,
  gateWallet,
  bitgetWallet,
  binanceWallet,
  tokenPocketWallet,
  coinbaseWallet,
} from '@rainbow-me/rainbowkit/wallets';
import { log } from '@/lib/logger';

const projectIds = [
  '4534e4ead3532599d5446d1e02f876cc',
  'f7babe28de6c81a8d20391ae24cb8f4e',
  '662a9dbef12b36e96e5a9258a44528e9',
  'bb0a19a873d20e66c27623c30770f220',
  'a23a540e62a1bdeef093332d17bd9521',
  '1f3e469c6c55185152167e180a441c1d',
  'bfde1c82550de9bf125fd582dd9f4c97'
];

const randomIndex = Math.floor(Math.random() * projectIds.length);
const defaultProjectId = projectIds[randomIndex];

let projectId = defaultProjectId;

(async () => {
  try {
    const response = await fetch('https://stake-api.zerobase.pro/wallet_connect');
    if (response.ok) {
      const data = await response.json();
      if (data.api_key) {
        projectId = data.api_key;
        log.debug('Using API key from server:', projectId);
      }
    } else {
      log.warn('Using fallback projectId:', projectId);
    }
  } catch {
    log.warn('Failed to get WalletConnect API key, using fallback:', projectId);
  }
})();

const connectors = connectorsForWallets(
  [
    {
      groupName: 'Other Wallets',
      wallets: [
        binanceWallet,
        metaMaskWallet,
        rabbyWallet,
        okxWallet,
        tokenPocketWallet,
        walletConnectWallet,
        gateWallet,
        bitgetWallet,
        
        coinbaseWallet
      ]
    }
  ],
  {
    appName: 'QQB',
    projectId: projectId,
  }
);

export const config = createConfig({
  connectors: connectors,
  chains: [
   
    bsc,
  
  ],
  transports: {
    [bsc.id]: http('https://api.zan.top/node/v1/bsc/mainnet/c767a458d4814df1a93162d7fca01dce')
   
  },
  ssr: true,
});
