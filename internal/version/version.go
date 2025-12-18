package version

// These variables are set at build time via ldflags
var (
	// Version is the semantic version (e.g., "v1.2.3" or "dev")
	Version = "dev"

	// Commit is the git commit hash
	Commit = "unknown"

	// BuildDate is the build timestamp (RFC3339 format)
	BuildDate = "unknown"
)

// Info returns all version information as a struct
type Info struct {
	Version   string `json:"version"`
	Commit    string `json:"commit"`
	BuildDate string `json:"build_date"`
}

// Get returns the current version information
func Get() Info {
	return Info{
		Version:   Version,
		Commit:    Commit,
		BuildDate: BuildDate,
	}
}
