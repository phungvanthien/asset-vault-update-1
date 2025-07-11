<script lang="ts">
	import InvestWidget from './InvestWidget.svelte';
	import Backtest from './Backtest.svelte';
	import AboutStrategy from './AboutStrategy.svelte';
	import PerformanceMetrics from './PerformanceMetrics.svelte';
	import WalletConnection from '../components/WalletConnection.svelte';
	import { onMount } from 'svelte';
	import { writable } from 'svelte/store';

	// Vault logic với wallet connection
	const vaultStatus = writable({
		total_shares: 0,
		total_usdt: 0,
		total_apt: 0,
		created_at: 0
	});
	const userBalance = writable({ shares: 0, usdt_balance: 0 });
	const loading = writable(false);
	const error = writable('');
	const API_BASE = 'http://localhost:5001/api/vault';
	const VAULT_ADDRESS = '0x2fdd1d8c08c6d2e447cffd67419cd9f0d53bedd003e5a6ee427b649f0c1077ef'; // Mainnet address
	
	let depositAmount = '';
	let withdrawShares = '';
	let rebalanceAmount = '';
	let userAddress = '';

	// Wallet event handlers
	function handleWalletConnect(address: string) {
		userAddress = address;
		loadUserBalance(address);
	}

	function handleWalletDisconnect() {
		userAddress = '';
		userBalance.set({ shares: 0, usdt_balance: 0 });
	}

	async function loadVaultStatus() {
		try {
			const response = await fetch(`${API_BASE}/status`);
			const data = await response.json();
			if (data.success) {
				const status = parseVaultStatus(data.data);
				vaultStatus.set(status);
			} else {
				error.set(data.error || 'Failed to load vault status');
			}
		} catch (err) {
			error.set('Failed to connect to API server');
		}
	}
	
	function parseVaultStatus(output: string) {
		return {
			total_shares: 100000000,
			total_usdt: 50000000,
			total_apt: 25000000,
			created_at: Date.now() / 1000
		};
	}
	
	async function loadUserBalance(address: string) {
		if (!address) return;
		try {
			const response = await fetch(`${API_BASE}/balance/${address}`);
			const data = await response.json();
			if (data.success) {
				const balance = parseUserBalance(data.data);
				userBalance.set(balance);
			} else {
				error.set(data.error || 'Failed to load user balance');
			}
		} catch (err) {
			error.set('Failed to load user balance');
		}
	}
	
	function parseUserBalance(output: string) {
		return {
			shares: 10000000,
			usdt_balance: 5000000
		};
	}
	
	async function deposit() {
		if (!depositAmount || !userAddress) {
			error.set('Please connect wallet or enter address and amount');
			return;
		}
		loading.set(true);
		error.set('');
		try {
			const response = await fetch(`${API_BASE}/deposit`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ amount: parseInt(depositAmount), user_address: userAddress })
			});
			const data = await response.json();
			if (data.success) {
				depositAmount = '';
				await loadVaultStatus();
				await loadUserBalance(userAddress);
			} else {
				error.set(data.error || 'Deposit failed');
			}
		} catch (err) {
			error.set('Failed to deposit');
		} finally {
			loading.set(false);
		}
	}
	
	async function withdraw() {
		if (!withdrawShares || !userAddress) {
			error.set('Please connect wallet or enter address and shares amount');
			return;
		}
		loading.set(true);
		error.set('');
		try {
			const response = await fetch(`${API_BASE}/withdraw`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ shares: parseInt(withdrawShares), user_address: userAddress })
			});
			const data = await response.json();
			if (data.success) {
				withdrawShares = '';
				await loadVaultStatus();
				await loadUserBalance(userAddress);
			} else {
				error.set(data.error || 'Withdraw failed');
			}
		} catch (err) {
			error.set('Failed to withdraw');
		} finally {
			loading.set(false);
		}
	}
	
	async function rebalance() {
		if (!rebalanceAmount || !userAddress) {
			error.set('Please connect wallet or enter address and USDT amount');
			return;
		}
		loading.set(true);
		error.set('');
		try {
			const response = await fetch(`${API_BASE}/rebalance`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ usdt_amount: parseInt(rebalanceAmount), owner_address: userAddress })
			});
			const data = await response.json();
			if (data.success) {
				rebalanceAmount = '';
				await loadVaultStatus();
			} else {
				error.set(data.error || 'Rebalance failed');
			}
		} catch (err) {
			error.set('Failed to rebalance');
		} finally {
			loading.set(false);
		}
	}
	
	function formatNumber(num: number): string {
		return (num / 1000000).toFixed(2);
	}
	
	function formatAddress(address: string): string {
		return address.substring(0, 6) + '...' + address.substring(address.length - 4);
	}
	
	function formatTimestamp(timestamp: number): string {
		return new Date(timestamp * 1000).toLocaleString();
	}

	onMount(() => { 
		loadVaultStatus();
	});
</script>

<main>
	<header class="container">
		<h1>ETHDubai 2023 hackathon</h1>
	</header>

	<InvestWidget />
	<AboutStrategy />

	<section class="container">
		<h2>Current performance</h2>
		<p>
			<strong>Not enough data.</strong>
		</p>
		<p>
			This strategy has not been running long enough to gather sufficient live trading performance
			data. Strategies may do trades weekly or monthly and it will take several rebalance cycles to
			reflect the true performance.
		</p>
	</section>

	<Backtest />

	<PerformanceMetrics />

	<section class="container">
		<h2>Strategy execution and source code</h2>
		<p>
			View <a
				href="https://github.com/tradingstrategy-ai/ethdubai-2023-hackathon/blob/master/notebook/ethdubai-hackathon.ipynb"
				>strategy notebook source code</a
			> on GitHub.
		</p>
	</section>

	<!-- Vault UI mới tích hợp vào đây nếu muốn -->
	<section class="container">
		<h2>Aptos Vault (DeFi on Aptos Mainnet)</h2>
		{#if $error}
			<div class="mb-6 p-4 bg-red-100 border border-red-400 text-red-700 rounded">{$error}</div>
		{/if}
		
		<!-- Wallet Connection Component -->
		<WalletConnection 
			onWalletConnect={handleWalletConnect}
			onWalletDisconnect={handleWalletDisconnect}
		/>

		<!-- Vault Status -->
		<div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
			<div class="bg-white p-6 rounded-lg shadow-md">
				<h3 class="text-lg font-semibold text-gray-900 mb-2">Total Shares</h3>
				<p class="text-3xl font-bold text-blue-600">{formatNumber($vaultStatus.total_shares)}</p>
			</div>
			<div class="bg-white p-6 rounded-lg shadow-md">
				<h3 class="text-lg font-semibold text-gray-900 mb-2">Total USDT</h3>
				<p class="text-3xl font-bold text-green-600">${formatNumber($vaultStatus.total_usdt)}</p>
			</div>
			<div class="bg-white p-6 rounded-lg shadow-md">
				<h3 class="text-lg font-semibold text-gray-900 mb-2">Total APT</h3>
				<p class="text-3xl font-bold text-purple-600">{formatNumber($vaultStatus.total_apt)} APT</p>
			</div>
		</div>

		<!-- User Balance -->
		<div class="bg-white p-6 rounded-lg shadow-md mb-8">
			<h2 class="text-2xl font-bold text-gray-900 mb-4">Your Vault Balance</h2>
			<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
				<div class="bg-gray-50 p-4 rounded-lg">
					<h3 class="text-lg font-semibold text-gray-900 mb-2">Your Shares</h3>
					<p class="text-2xl font-bold text-blue-600">{formatNumber($userBalance.shares)}</p>
				</div>
				<div class="bg-gray-50 p-4 rounded-lg">
					<h3 class="text-lg font-semibold text-gray-900 mb-2">USDT Value</h3>
					<p class="text-2xl font-bold text-green-600">${formatNumber($userBalance.usdt_balance)}</p>
				</div>
			</div>
			<button on:click={() => loadUserBalance(userAddress)} class="mt-4 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">Refresh Balance</button>
		</div>

		<!-- Vault Actions -->
		<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
			<div class="bg-white p-6 rounded-lg shadow-md">
				<h3 class="text-xl font-bold text-gray-900 mb-4">💰 Deposit USDT</h3>
				<div class="mb-4">
					<label for="depositAmount" class="block text-sm font-medium text-gray-700 mb-2">Amount (USDT)</label>
					<input id="depositAmount" type="number" bind:value={depositAmount} placeholder="Enter amount" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
				</div>
				<button on:click={deposit} disabled={$loading || !userAddress} class="w-full px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 disabled:opacity-50">
					{$loading ? 'Processing...' : 'Deposit'}
				</button>
			</div>
			<div class="bg-white p-6 rounded-lg shadow-md">
				<h3 class="text-xl font-bold text-gray-900 mb-4">💸 Withdraw USDT</h3>
				<div class="mb-4">
					<label for="withdrawShares" class="block text-sm font-medium text-gray-700 mb-2">Shares to Burn</label>
					<input id="withdrawShares" type="number" bind:value={withdrawShares} placeholder="Enter shares" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
				</div>
				<button on:click={withdraw} disabled={$loading || !userAddress} class="w-full px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 disabled:opacity-50">
					{$loading ? 'Processing...' : 'Withdraw'}
				</button>
			</div>
			<div class="bg-white p-6 rounded-lg shadow-md">
				<h3 class="text-xl font-bold text-gray-900 mb-4">⚖️ Rebalance</h3>
				<div class="mb-4">
					<label for="rebalanceAmount" class="block text-sm font-medium text-gray-700 mb-2">USDT to Swap for APT</label>
					<input id="rebalanceAmount" type="number" bind:value={rebalanceAmount} placeholder="Enter USDT amount" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
				</div>
				<button on:click={rebalance} disabled={$loading || !userAddress} class="w-full px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 disabled:opacity-50">
					{$loading ? 'Processing...' : 'Rebalance'}
				</button>
			</div>
		</div>

		<!-- Vault Information -->
		<div class="mt-8 bg-white p-6 rounded-lg shadow-md">
			<h2 class="text-2xl font-bold text-gray-900 mb-4">Vault Information</h2>
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
				<div>
					<p><strong>Network:</strong> Aptos Mainnet</p>
					<p><strong>Vault Address:</strong> {formatAddress(VAULT_ADDRESS)}</p>
					<p><strong>Created:</strong> {formatTimestamp($vaultStatus.created_at)}</p>
				</div>
				<div>
					<p><strong>USDT LayerZero:</strong> 0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT</p>
					<p><strong>APT Token:</strong> 0x1::aptos_coin::AptosCoin</p>
					<p><strong>PancakeSwap Router:</strong> 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60</p>
				</div>
			</div>
			<div class="mt-4 p-4 bg-blue-50 rounded-lg">
				<h3 class="text-lg font-semibold text-blue-900 mb-2">ℹ️ USDT LayerZero Information</h3>
				<p class="text-sm text-blue-800">
					This vault uses USDT LayerZero (cross-chain USDT) on Aptos Mainnet. 
					You can bridge USDT from other chains using LayerZero protocol.
				</p>
				<p class="text-sm text-blue-800 mt-2">
					<a href="https://explorer.aptoslabs.com/coin/0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT?network=mainnet" 
					   target="_blank" class="text-blue-600 hover:text-blue-800 underline">
						View USDT LayerZero on Explorer →
					</a>
				</p>
			</div>
		</div>
	</section>
</main>

<style>
	.container {
		min-height: 100vh;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
	}
</style>
