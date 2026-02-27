package config

import env "github.com/caarlos0/env/v11"

type Config struct {
	Server            ServerConfig
	Database          DatabaseConfig
	Redis             RedisConfig
	Providers         ProviderConfig
	Gmail             GmailConfig
	Supabase          SupabaseConfig
	OpenAI            OpenAIConfig
	OpenExchangeRates OpenExchangeRatesConfig
	FCM               FCMConfig
}

type ProviderConfig struct {
	Auth         string `env:"AUTH_PROVIDER"          envDefault:"supabase"`
	LLM          string `env:"LLM_PROVIDER"           envDefault:"openai"`
	ExchangeRate string `env:"EXCHANGE_RATE_PROVIDER"  envDefault:"openexchangerates"`
	Notification string `env:"NOTIFICATION_PROVIDER"   envDefault:"fcm"`
}

type GmailConfig struct {
	ClientID     string `env:"GMAIL_CLIENT_ID"`
	ClientSecret string `env:"GMAIL_CLIENT_SECRET"`
	RedirectURL  string `env:"GMAIL_REDIRECT_URL"`
	PubSubTopic  string `env:"GMAIL_PUBSUB_TOPIC"`
	WebhookURL   string `env:"GMAIL_WEBHOOK_URL"`
}

type SupabaseConfig struct {
	URL       string `env:"SUPABASE_URL"`
	AnonKey   string `env:"SUPABASE_ANON_KEY"`
	JWTSecret string `env:"SUPABASE_JWT_SECRET"`
}

type OpenAIConfig struct {
	APIKey string `env:"OPENAI_API_KEY"`
	Model  string `env:"OPENAI_MODEL" envDefault:"gpt-4o"`
}

type OpenExchangeRatesConfig struct {
	AppID   string `env:"OPENEXCHANGERATES_APP_ID"`
	BaseURL string `env:"OPENEXCHANGERATES_BASE_URL" envDefault:"https://openexchangerates.org/api"`
}

type FCMConfig struct {
	CredentialsFile string `env:"FCM_CREDENTIALS_FILE"`
	ProjectID       string `env:"FCM_PROJECT_ID"`
}

type ServerConfig struct {
	Port        int    `env:"PORT"        envDefault:"8080"`
	Environment string `env:"ENVIRONMENT" envDefault:"development"`
	LogLevel    string `env:"LOG_LEVEL"   envDefault:"info"`
}

type DatabaseConfig struct {
	URL         string `env:"DATABASE_URL,required"`
	AutoMigrate bool   `env:"DATABASE_AUTO_MIGRATE" envDefault:"true"`
}

type RedisConfig struct {
	URL string `env:"REDIS_URL,required"`
}

func Load() (*Config, error) {
	cfg := &Config{}
	if err := env.Parse(cfg); err != nil {
		return nil, err
	}
	return cfg, nil
}
