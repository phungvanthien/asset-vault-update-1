<script lang="ts">
	import { formatAddress } from '$lib/helpers/formatters';
	import { Button } from '$lib/components';

	let investAmount = '';
	let balance: string = '---';
	let vaultStatus: any = null;
	let loading = false;
	let error = '';

	// API endpoints
	const API_BASE = 'http://localhost:5001/api/vault';
	const VAULT_ADDRESS = '0xc8fa51ab7f319d232099afe32ebc9f57b898879dc724fb4f71b4d92f62ea0a77';

	// Load vault status on mount
	onMount(async () => {
		await loadVaultStatus();
	});

	async function loadVaultStatus() {
		try {
			const response = await fetch(`${API_BASE}/status`);
			if (response.ok) {
				vaultStatus = await response.json();
				balance = vaultStatus.user_shares ? `${vaultStatus.user_shares} shares` : '0 shares';
			}
		} catch (err) {
			console.error('Failed to load vault status:', err);
			error = 'Failed to connect to vault API';
		}
	}

	async function deposit() {
		if (!investAmount || parseFloat(investAmount) <= 0) {
			error = 'Please enter a valid amount';
			return;
		}

		loading = true;
		error = '';

		try {
			const response = await fetch(`${API_BASE}/deposit`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify({
					amount: parseInt(investAmount)
				})
			});

			const result = await response.json();
			
			if (result.success) {
				error = '';
				investAmount = '';
				await loadVaultStatus();
				alert(`Deposit successful! Transaction: ${result.tx_hash}`);
			} else {
				error = result.error || 'Deposit failed';
			}
		} catch (err) {
			console.error('Deposit error:', err);
			error = 'Failed to deposit';
		} finally {
			loading = false;
		}
	}

	async function withdraw() {
		if (!investAmount || parseFloat(investAmount) <= 0) {
			error = 'Please enter a valid amount';
			return;
		}

		loading = true;
		error = '';

		try {
			const response = await fetch(`${API_BASE}/withdraw`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify({
					amount: parseInt(investAmount)
				})
			});

			const result = await response.json();
			
			if (result.success) {
				error = '';
				investAmount = '';
				await loadVaultStatus();
				alert(`Withdraw successful! Transaction: ${result.tx_hash}`);
			} else {
				error = result.error || 'Withdraw failed';
			}
		} catch (err) {
			console.error('Withdraw error:', err);
			error = 'Failed to withdraw';
		} finally {
			loading = false;
		}
	}

	import { onMount } from 'svelte';
</script>

<section class="container">
	<div class="invest-widget">
		<div class="info">
			<p>
				<span class="label">Vault Address:</span><br />
				{formatAddress(VAULT_ADDRESS)}
			</p>
			<p>
				<span class="label">Your shares:</span><br />
				{balance}
			</p>
			{#if vaultStatus}
				<p>
					<span class="label">Total vault shares:</span><br />
					{vaultStatus.total_shares}
				</p>
			{/if}
			<p>
				<label for="invest-amount">Amount to invest:</label><br />
				<input id="invest-amount" type="number" bind:value={investAmount} disabled={loading} />
			</p>
			{#if error}
				<p class="error">{error}</p>
			{/if}
		</div>

		<div class="ctas">
			<Button 
				label={loading ? "Processing..." : "Deposit Shares"} 
				on:click={deposit}
				disabled={loading || !investAmount}
			/>
			<Button 
				label={loading ? "Processing..." : "Withdraw Shares"} 
				on:click={withdraw}
				disabled={loading || !investAmount}
			/>
			<Button 
				label="Refresh Status" 
				on:click={loadVaultStatus}
				disabled={loading}
			/>
		</div>
	</div>
</section>

<style>
	.invest-widget {
		display: grid;
		grid-template-columns: 1fr auto;
		border-radius: 1rem;
		padding: 1.5rem;
		font-size: 18px;
		background: var(--c-accent);
	}

	.ctas {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.info p {
		margin: 0 0 1.5rem 0;
	}

	.info label,
	.info span.label {
		font-weight: bold;
	}

	.info input {
		font-family: monospace;
		font-size: inherit;
		padding: 0.25rem;
		width: 9em;
	}

	.error {
		color: #ff4444;
		font-weight: bold;
	}

	@media (max-width: 576px) {
		.invest-widget {
			grid-template-columns: auto;
		}
	}
</style>
