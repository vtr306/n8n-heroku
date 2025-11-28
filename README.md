# n8n-heroku

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/vtr306/n8n-heroku/tree/main)

## n8n - Free and open fair-code licensed node based Workflow Automation Tool.

This is a [Heroku](https://heroku.com/)-focused container implementation of [n8n](https://n8n.io/).

Use the **Deploy to Heroku** button above to launch n8n on Heroku. When deploying, make sure to check all configuration options and adjust them to your needs. It's especially important to set `N8N_ENCRYPTION_KEY` to a random secure value. 

## Queue Mode

This deployment is configured with **Queue Mode** enabled by default, which allows for better scalability and performance. The setup includes:

- **Redis**: Automatically provisioned via Heroku Redis addon (required for queue mode)
- **Web Dyno**: Handles the n8n UI and API
- **Worker Dyno**: Processes workflow executions
- **Webhook Dyno**: Handles incoming webhook requests

### Scaling Workers

After the initial deploy, you may need to manually scale the worker dynos. Use the Heroku CLI:

```bash
# Scale workers (replace <app-name> with your Heroku app name)
heroku ps:scale worker=2 --app <app-name>

# Or if you're already in the app directory
heroku ps:scale worker=2
```

You can also scale webhook processors if needed:

```bash
heroku ps:scale webhook=1
```

**Note:** If workers or webhooks don't appear after deploy, make sure to:
1. Commit and push the updated `heroku.yml` file (which now includes worker and webhook processes)
2. Or manually scale using the commands above

### Adding Redis Addon

If the Redis addon doesn't appear automatically after deploy, you can add it manually:

```bash
heroku addons:create heroku-redis:mini --app <app-name>
```

After adding Redis, the `REDIS_URL` environment variable will be automatically set, and the entrypoint script will configure n8n to use it.

### Configuration

The `EXECUTIONS_MODE` environment variable is set to `queue` by default. The Redis connection is automatically configured from the `REDIS_URL` provided by Heroku.

Refer to the [Heroku n8n tutorial](https://docs.n8n.io/hosting/server-setups/heroku/) and [Queue Mode documentation](https://docs.n8n.io/hosting/scaling/queue-mode/) for more information.

If you have questions after trying the tutorials, check out the [forums](https://community.n8n.io/).
