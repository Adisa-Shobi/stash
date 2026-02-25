package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"

	"github.com/shobi/stash-backend/internal/config"
	"github.com/shobi/stash-backend/internal/database"
	"github.com/shobi/stash-backend/internal/logging"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	logger := logging.New(cfg.Server.Environment, cfg.Server.LogLevel)
	slog.SetDefault(logger)

	if cfg.Database.AutoMigrate {
		logger.Info("running database migrations")
		if err := database.RunMigrations(cfg.Database.URL); err != nil {
			logger.Error("failed to run migrations", "error", err)
			os.Exit(1)
		}
		logger.Info("database migrations applied")
	}

	ctx := context.Background()

	pool := connectDB(ctx, cfg.Database.URL)
	defer pool.Close()

	rdb := connectRedis(ctx, cfg.Redis.URL)
	defer func() { _ = rdb.Close() }()

	app := fiber.New()
	app.Use(logging.Middleware(logger))
	app.Get("/health", healthHandler(pool, rdb))

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-quit
		logger.Info("shutting down server")
		_ = app.Shutdown()
	}()

	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Info("starting server", "address", addr)
	if err := app.Listen(addr); err != nil {
		logger.Error("server error", "error", err)
		os.Exit(1)
	}
}

func connectDB(ctx context.Context, url string) *pgxpool.Pool {
	pool, err := pgxpool.New(ctx, url)
	if err != nil {
		slog.Error("failed to create database pool", "error", err)
		os.Exit(1)
	}
	if err := pool.Ping(ctx); err != nil {
		slog.Error("failed to ping database", "error", err)
		os.Exit(1)
	}
	slog.Info("connected to database")
	return pool
}

func connectRedis(ctx context.Context, url string) *redis.Client {
	opts, err := redis.ParseURL(url)
	if err != nil {
		slog.Error("failed to parse redis URL", "error", err)
		os.Exit(1)
	}
	rdb := redis.NewClient(opts)
	if err := rdb.Ping(ctx).Err(); err != nil {
		slog.Error("failed to ping redis", "error", err)
		os.Exit(1)
	}
	slog.Info("connected to redis")
	return rdb
}

func healthHandler(pool *pgxpool.Pool, rdb *redis.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		status := "ok"
		httpStatus := fiber.StatusOK

		dbStatus := "healthy"
		if err := pool.Ping(c.Context()); err != nil {
			dbStatus = "unhealthy"
			status = "degraded"
			httpStatus = fiber.StatusServiceUnavailable
		}

		redisStatus := "healthy"
		if err := rdb.Ping(c.Context()).Err(); err != nil {
			redisStatus = "unhealthy"
			status = "degraded"
			httpStatus = fiber.StatusServiceUnavailable
		}

		return c.Status(httpStatus).JSON(fiber.Map{
			"status":   status,
			"database": dbStatus,
			"redis":    redisStatus,
		})
	}
}
