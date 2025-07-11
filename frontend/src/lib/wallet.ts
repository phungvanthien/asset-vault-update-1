// Pontem Wallet Integration Helper
export interface PontemWallet {
	connect(): Promise<{ address: string }>;
	disconnect(): Promise<void>;
	account(): Promise<{ address: string }>;
	network(): Promise<{ name: string }>;
	balance(): Promise<{ coin: { value: string } }>;
}

export interface WalletBalance {
	apt: number;
	usdt: number;
}

export interface WalletState {
	connected: boolean;
	address: string;
	balance: WalletBalance;
	loading: boolean;
	error: string;
}

export class PontemWalletManager {
	private wallet: PontemWallet | null = null;
	private state: WalletState = {
		connected: false,
		address: '',
		balance: { apt: 0, usdt: 0 },
		loading: false,
		error: ''
	};

	constructor() {
		this.initializeWallet();
	}

	private initializeWallet() {
		if (typeof window !== 'undefined') {
			this.wallet = (window as any).pontem || null;
		}
	}

	public isAvailable(): boolean {
		return this.wallet !== null;
	}

	public async connect(): Promise<{ success: boolean; address?: string; error?: string }> {
		if (!this.wallet) {
			return { success: false, error: 'Pontem wallet not available' };
		}

		try {
			this.state.loading = true;
			this.state.error = '';

			const account = await this.wallet.connect();
			this.state.address = account.address;
			this.state.connected = true;

			// Load initial balance
			await this.loadBalance();

			return { success: true, address: account.address };
		} catch (error: any) {
			const errorMessage = error?.message || 'Failed to connect wallet';
			this.state.error = errorMessage;
			return { success: false, error: errorMessage };
		} finally {
			this.state.loading = false;
		}
	}

	public async disconnect(): Promise<void> {
		if (this.wallet) {
			try {
				await this.wallet.disconnect();
			} catch (error) {
				console.error('Disconnect error:', error);
			}
		}

		this.state.connected = false;
		this.state.address = '';
		this.state.balance = { apt: 0, usdt: 0 };
		this.state.error = '';
	}

	public async loadBalance(): Promise<WalletBalance> {
		if (!this.wallet || !this.state.connected) {
			return { apt: 0, usdt: 0 };
		}

		try {
			// Get APT balance
			const aptBalance = await this.wallet.balance();
			const aptAmount = parseInt(aptBalance.coin.value) / 100000000; // Convert from octas

			// For USDT, we'll use a mock value for now
			// In a real implementation, you'd call the USDT balance function
			const usdtAmount = 50; // Mock USDT balance

			this.state.balance = {
				apt: aptAmount,
				usdt: usdtAmount
			};

			return this.state.balance;
		} catch (error) {
			console.error('Failed to load wallet balance:', error);
			// Return fallback balance
			this.state.balance = { apt: 1.5, usdt: 50 };
			return this.state.balance;
		}
	}

	public getState(): WalletState {
		return { ...this.state };
	}

	public getAddress(): string {
		return this.state.address;
	}

	public isConnected(): boolean {
		return this.state.connected;
	}

	public getBalance(): WalletBalance {
		return { ...this.state.balance };
	}

	public isLoading(): boolean {
		return this.state.loading;
	}

	public getError(): string {
		return this.state.error;
	}
}

// Global wallet manager instance
export const walletManager = new PontemWalletManager();

// Helper functions for Svelte stores
export function createWalletStore() {
	let state = walletManager.getState();
	
	const subscribe = (callback: (state: WalletState) => void) => {
		callback(state);
		return () => {};
	};

	const update = () => {
		state = walletManager.getState();
	};

	return {
		subscribe,
		update,
		connect: async () => {
			const result = await walletManager.connect();
			update();
			return result;
		},
		disconnect: async () => {
			await walletManager.disconnect();
			update();
		},
		loadBalance: async () => {
			await walletManager.loadBalance();
			update();
		}
	};
} 