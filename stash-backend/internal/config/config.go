package config

import env "github.com/caarlos0/env/v11"

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
}

type ServerConfig struct {
	Port        int    `env:"PORT"        envDefault:"8080"`
	Environment string `env:"ENVIRONMENT" envDefault:"development"`
	LogLevel    string `env:"LOG_LEVEL"   envDefault:"info"`
}

type DatabaseConfig struct {
	URL string `env:"DATABASE_URL,required"`
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
