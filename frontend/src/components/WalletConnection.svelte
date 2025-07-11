<script lang="ts">
	import { walletManager, type WalletState } from '$lib/wallet';
	import { writable } from 'svelte/store';

	export let onWalletConnect: (address: string) => void = () => {};
	export let onWalletDisconnect: () => void = () => {};

	const walletState = writable<WalletState>({
		connected: false,
		address: '',
		balance: { apt: 0, usdt: 0 },
		loading: false,
		error: ''
	});

	let userAddress = '';

	async function connectWallet() {
		const result = await walletManager.connect();
		if (result.success && result.address) {
			userAddress = result.address;
			onWalletConnect(result.address);
		}
		updateWalletState();
	}

	async function disconnectWallet() {
		await walletManager.disconnect();
		userAddress = '';
		onWalletDisconnect();
		updateWalletState();
	}

	async function refreshWalletBalance() {
		await walletManager.loadBalance();
		updateWalletState();
	}

	function updateWalletState() {
		walletState.set(walletManager.getState());
	}

	function formatAddress(address: string): string {
		return address.substring(0, 6) + '...' + address.substring(address.length - 4);
	}

	// Update wallet state on mount
	updateWalletState();
</script>

<div class="bg-white p-6 rounded-lg shadow-md mb-8">
	<h3 class="text-xl font-bold text-gray-900 mb-4">🔗 Connect Wallet</h3>
	{#if !$walletState.connected}
		<div class="flex flex-col sm:flex-row gap-4">
			{#if walletManager.isAvailable()}
				<button 
					on:click={connectWallet} 
					disabled={$walletState.loading}
					class="px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{$walletState.loading ? '🔄 Connecting...' : '🔗 Connect Pontem Wallet'}
				</button>
			{:else}
				<div class="px-6 py-3 bg-yellow-100 border border-yellow-400 text-yellow-700 rounded-md">
					⚠️ Pontem wallet not detected. 
					<a href="https://pontem.network/" target="_blank" class="underline">Install Pontem Wallet</a>
				</div>
			{/if}
			<div class="text-sm text-gray-600">
				<p>Or manually enter your Aptos address:</p>
				<input 
					type="text" 
					bind:value={userAddress} 
					placeholder="Enter your Aptos address" 
					class="mt-2 w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" 
				/>
			</div>
		</div>
		{#if $walletState.error}
			<div class="mt-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded-md">
				⚠️ {$walletState.error}
			</div>
		{/if}
	{:else}
		<div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
			<div class="flex-1">
				<div class="flex items-center gap-2 mb-2">
					<span class="w-3 h-3 bg-green-500 rounded-full"></span>
					<p class="text-sm text-gray-600">Connected Address:</p>
				</div>
				<p class="font-mono text-lg font-bold text-blue-600">{formatAddress($walletState.address)}</p>
				<div class="mt-2 flex gap-4 text-sm">
					<span class="text-green-600">APT: {$walletState.balance.apt.toFixed(4)}</span>
					<span class="text-blue-600">USDT: ${$walletState.balance.usdt.toFixed(2)}</span>
				</div>
				<button 
					on:click={refreshWalletBalance} 
					class="mt-2 text-xs text-blue-600 hover:text-blue-800 underline"
				>
					🔄 Refresh Balance
				</button>
			</div>
			<button 
				on:click={disconnectWallet} 
				class="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
			>
				Disconnect
			</button>
		</div>
	{/if}
</div> 