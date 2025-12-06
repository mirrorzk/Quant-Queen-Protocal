import { log } from "@/lib/logger";
import Decimal from "decimal.js";

export function calculateDaysPassed(claimTime: number | bigint): number {
    const claimTimeInMillis = Number(claimTime) * 1000;
    const transactionDate = new Date(claimTimeInMillis);
    const currentDate = new Date();
  
    const timeDifference = currentDate.getTime() - transactionDate.getTime();
    const daysSinceTransaction = timeDifference / (1000 * 60 * 60 * 24);
  
    return Math.floor(daysSinceTransaction);
  }
  
  export function hasClaimTimePassed(claimTime: number | bigint) {
    const currentTime = BigInt(Math.floor(Date.now() / 1000)); 
    log.debug('currentTime: ',currentTime)
    log.debug('claimTime: ',claimTime)
    log.debug('currentTime >= claimTime: ',currentTime >= claimTime)
    return currentTime >= claimTime; 
}

export function shortAddress(addr: string, head = 6, tail = 4) {
  if (!addr) return '';
  return addr.length > head + tail
    ? `${addr.slice(0, head)}....${addr.slice(-tail)}`
    : addr;
}

export function isEqualAddress(a: string, b: string) {
  return a.toLowerCase() === b.toLowerCase()
}

export function safeToLocaleString (value: string | number | bigint | null | undefined): string{
  if (value === null || value === undefined || value === '') {
    return '0.00';
  }

  let numericValue: string;

  if (typeof value === 'bigint') {
    numericValue = value.toString();
  } else {
    numericValue = String(value);
  }

  if (!isNaN(Number(numericValue))) {
    try {
      let decimalValue = new Decimal(numericValue);

      if (!decimalValue.isInteger()) {
        decimalValue = decimalValue.toDecimalPlaces(2, Decimal.ROUND_DOWN);
      }

      return decimalValue.toNumber().toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      });
    } catch (error) {
      console.error('create Decimal error:', error);
    }
  }

  return '0.00';
};

export function formatAmount({
  amount,
  decimal,
}: {
  amount: string;
  decimal: number;
}) {
  const decimalAmount = new Decimal(amount.toString()).dividedBy(new Decimal(10).pow(decimal));
  const formatted = decimalAmount.toFixed(decimal, Decimal.ROUND_DOWN);

  const [integer, decimalPart] = formatted.split('.');

  return decimalPart === '0'.repeat(decimal) ? integer : formatted;
}