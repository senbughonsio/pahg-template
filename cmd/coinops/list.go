package main

import (
	"fmt"
	"os"
	"text/tabwriter"
	"time"

	"github.com/spf13/cobra"

	"pahg-template/internal/coingecko"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all configured coins with current prices",
	Long: `Fetches and displays all configured coins with their current prices
and 24-hour change. Useful for debugging configuration issues.

Output is TSV format suitable for piping to other tools.`,
	RunE: runList,
}

func init() {
	rootCmd.AddCommand(listCmd)
}

func runList(cmd *cobra.Command, args []string) error {
	cfg := GetConfig()

	fmt.Fprintf(os.Stderr, "Config source: %s\n", GetConfigSource())
	fmt.Fprintf(os.Stderr, "Coins configured: %d\n", len(cfg.Coins))
	fmt.Fprintf(os.Stderr, "Timestamp: %s\n\n", time.Now().UTC().Format(time.RFC3339))

	if len(cfg.Coins) == 0 {
		fmt.Fprintln(os.Stderr, "ERROR: No coins configured!")
		return nil
	}

	// Print all configured coins first (config validation)
	fmt.Fprintln(os.Stderr, "Configured coins:")
	for i, c := range cfg.Coins {
		fmt.Fprintf(os.Stderr, "  %3d. %s (%s)\n", i+1, c.ID, c.DisplayName)
	}
	fmt.Fprintln(os.Stderr)

	// Create CoinGecko service with our coins
	service := coingecko.NewService(cfg.Coins)

	// Fetch prices
	fmt.Fprintf(os.Stderr, "Fetching prices for %d coins from CoinGecko...\n", len(cfg.Coins))
	coins, err := service.GetPrices()
	if err != nil {
		return fmt.Errorf("failed to fetch prices: %w", err)
	}
	fmt.Fprintf(os.Stderr, "Received %d price entries\n\n", len(coins))

	// Output as TSV
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "ID\tDISPLAY_NAME\tUSD\t24H_CHANGE")

	for _, coin := range coins {
		fmt.Fprintf(w, "%s\t%s\t%.2f\t%.2f%%\n",
			coin.ID,
			coin.DisplayName,
			coin.Price,
			coin.Change24h,
		)
	}

	w.Flush()
	return nil
}
