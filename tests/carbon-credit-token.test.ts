// Test for Carbon Credit Token Contract
import { describe, it, expect, beforeEach } from 'vitest';

interface MockContract {
  admin: string;
  paused: boolean;
  totalSupply: bigint;
  balances: Map<string, bigint>;
  allowances: Map<string, bigint>; // Key as 'owner-spender'
  stakedBalances: Map<string, bigint>;
  oracle: string;
  MAX_SUPPLY: bigint;

  isAdmin(caller: string): boolean;
  setPaused(caller: string, pause: boolean): { value: boolean } | { error: number };
  setOracle(caller: string, newOracle: string): { value: boolean } | { error: number };
  mint(caller: string, recipient: string, amount: bigint): { value: boolean } | { error: number };
  burn(caller: string, amount: bigint): { value: boolean } | { error: number };
  transfer(caller: string, recipient: string, amount: bigint): { value: boolean } | { error: number };
  approve(caller: string, spender: string, amount: bigint): { value: boolean } | { error: number };
  transferFrom(caller: string, owner: string, recipient: string, amount: bigint): { value: boolean } | { error: number };
  stake(caller: string, amount: bigint): { value: boolean } | { error: number };
  unstake(caller: string, amount: bigint): { value: boolean } | { error: number };
}

const mockContract: MockContract = {
  admin: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  paused: false,
  totalSupply: 0n,
  balances: new Map(),
  allowances: new Map(),
  stakedBalances: new Map(),
  oracle: 'SP000000000000000000002Q6VF78',
  MAX_SUPPLY: 100_000_000_000_000n,

  isAdmin(caller: string) {
    return caller === this.admin;
  },

  setPaused(caller: string, pause: boolean) {
    if (!this.isAdmin(caller)) return { error: 100 };
    this.paused = pause;
    return { value: pause };
  },

  setOracle(caller: string, newOracle: string) {
    if (!this.isAdmin(caller)) return { error: 100 };
    this.oracle = newOracle;
    return { value: true };
  },

  mint(caller: string, recipient: string, amount: bigint) {
    if (!this.isAdmin(caller)) return { error: 100 };
    if (amount <= 0n) return { error: 106 };
    if (this.totalSupply + amount > this.MAX_SUPPLY) return { error: 103 };
    this.balances.set(recipient, (this.balances.get(recipient) || 0n) + amount);
    this.totalSupply += amount;
    return { value: true };
  },

  burn(caller: string, amount: bigint) {
    if (this.paused) return { error: 104 };
    if (amount <= 0n) return { error: 106 };
    const bal = this.balances.get(caller) || 0n;
    if (bal < amount) return { error: 101 };
    this.balances.set(caller, bal - amount);
    this.totalSupply -= amount;
    return { value: true };
  },

  transfer(caller: string, recipient: string, amount: bigint) {
    if (this.paused) return { error: 104 };
    if (amount <= 0n) return { error: 106 };
    const bal = this.balances.get(caller) || 0n;
    if (bal < amount) return { error: 101 };
    this.balances.set(caller, bal - amount);
    this.balances.set(recipient, (this.balances.get(recipient) || 0n) + amount);
    return { value: true };
  },

  approve(caller: string, spender: string, amount: bigint) {
    if (this.paused) return { error: 104 };
    if (amount <= 0n) return { error: 106 };
    const key = `${caller}-${spender}`;
    if (this.allowances.has(key)) return { error: 108 };
    this.allowances.set(key, amount);
    return { value: true };
  },

  transferFrom(caller: string, owner: string, recipient: string, amount: bigint) {
    if (this.paused) return { error: 104 };
    if (amount <= 0n) return { error: 106 };
    const key = `${owner}-${caller}`;
    const allowance = this.allowances.get(key) || 0n;
    if (allowance < amount) return { error: 102 };
    const ownerBal = this.balances.get(owner) || 0n;
    if (ownerBal < amount) return { error: 101 };
    this.allowances.set(key, allowance - amount);
    this.balances.set(owner, ownerBal - amount);
    this.balances.set(recipient, (this.balances.get(recipient) || 0n) + amount);
    return { value: true };
  },

  stake(caller: string, amount: bigint) {
    if (this.paused) return { error: 104 };
    if (amount <= 0n) return { error: 106 };
    const bal = this.balances.get(caller) || 0n;
    if (bal < amount) return { error: 101 };
    this.balances.set(caller, bal - amount);
    this.stakedBalances.set(caller, (this.stakedBalances.get(caller) || 0n) + amount);
    return { value: true };
  },

  unstake(caller: string, amount: bigint) {
    if (this.paused) return { error: 104 };
    if (amount <= 0n) return { error: 106 };
    const stakeBal = this.stakedBalances.get(caller) || 0n;
    if (stakeBal < amount) return { error: 101 };
    this.stakedBalances.set(caller, stakeBal - amount);
    this.balances.set(caller, (this.balances.get(caller) || 0n) + amount);
    return { value: true };
  },
};

describe('EcoFlow Carbon Credit Token Contract', () => {
  beforeEach(() => {
    mockContract.admin = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
    mockContract.paused = false;
    mockContract.totalSupply = 0n;
    mockContract.balances = new Map();
    mockContract.allowances = new Map();
    mockContract.stakedBalances = new Map();
    mockContract.oracle = 'SP000000000000000000002Q6VF78';
  });

  it('should allow admin to mint tokens', () => {
    const result = mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 1000n);
    expect(result).toEqual({ value: true });
    expect(mockContract.balances.get('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB')).toBe(1000n);
    expect(mockContract.totalSupply).toBe(1000n);
  });

  it('should prevent non-admin from minting', () => {
    const result = mockContract.mint('ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP', 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 1000n);
    expect(result).toEqual({ error: 100 });
  });

  it('should prevent minting over max supply', () => {
    const result = mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 200_000_000_000_000n);
    expect(result).toEqual({ error: 103 });
  });

  it('should allow burning tokens', () => {
    mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 500n);
    const result = mockContract.burn('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 200n);
    expect(result).toEqual({ value: true });
    expect(mockContract.balances.get('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB')).toBe(300n);
    expect(mockContract.totalSupply).toBe(300n);
  });

  it('should prevent burning more than balance', () => {
    mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 500n);
    const result = mockContract.burn('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 600n);
    expect(result).toEqual({ error: 101 });
  });

  it('should allow transfers', () => {
    mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 500n);
    const result = mockContract.transfer('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP', 200n);
    expect(result).toEqual({ value: true });
    expect(mockContract.balances.get('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB')).toBe(300n);
    expect(mockContract.balances.get('ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP')).toBe(200n);
  });

  it('should prevent transfers when paused', () => {
    mockContract.setPaused(mockContract.admin, true);
    const result = mockContract.transfer('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP', 200n);
    expect(result).toEqual({ error: 104 });
  });

  it('should allow approvals and transfer-from', () => {
    mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 500n);
    const approveResult = mockContract.approve('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP', 300n);
    expect(approveResult).toEqual({ value: true });
    const transferFromResult = mockContract.transferFrom('ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP', 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 'ST4ABC...', 200n);
    expect(transferFromResult).toEqual({ value: true });
    expect(mockContract.balances.get('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB')).toBe(300n);
    expect(mockContract.balances.get('ST4ABC...')).toBe(200n);
  });

  it('should prevent transfer-from without sufficient allowance', () => {
    mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 500n);
    mockContract.approve('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP', 100n);
    const result = mockContract.transferFrom('ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP', 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 'ST4ABC...', 200n);
    expect(result).toEqual({ error: 102 });
  });

  it('should allow staking and unstaking', () => {
    mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 500n);
    const stakeResult = mockContract.stake('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 200n);
    expect(stakeResult).toEqual({ value: true });
    expect(mockContract.balances.get('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB')).toBe(300n);
    expect(mockContract.stakedBalances.get('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB')).toBe(200n);
    const unstakeResult = mockContract.unstake('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 100n);
    expect(unstakeResult).toEqual({ value: true });
    expect(mockContract.stakedBalances.get('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB')).toBe(100n);
    expect(mockContract.balances.get('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB')).toBe(400n);
  });

  it('should prevent staking more than balance', () => {
    mockContract.mint(mockContract.admin, 'ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 500n);
    const result = mockContract.stake('ST2CY5V39NHDPWSXMW9QDWCGP6E6P29JG0R82QYB', 600n);
    expect(result).toEqual({ error: 101 });
  });
});