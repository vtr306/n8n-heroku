# n8n-heroku

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/vtr306/n8n-heroku/tree/main)

## n8n - Free and open fair-code licensed node based Workflow Automation Tool.

This is a [Heroku](https://heroku.com/)-focused container implementation of [n8n](https://n8n.io/).

Use the **Deploy to Heroku** button above to launch n8n on Heroku. When deploying, make sure to check all configuration options and adjust them to your needs. It's especially important to set `N8N_ENCRYPTION_KEY` to a random secure value. 

## Queue Mode

This deployment is configured with **Queue Mode** enabled by default, which allows for better scalability and performance. The setup includes:

- **Redis**: Automatically provisioned via Heroku Redis addon
- **Web Dyno**: Handles the n8n UI and API
- **Worker Dyno**: Processes workflow executions

### Scaling Workers

To scale the number of worker dynos, use the Heroku CLI:

```bash
heroku ps:scale worker=2
```

You can also scale webhook processors if needed:

```bash
heroku ps:scale webhook=1
```

### Configuration

The `EXECUTIONS_MODE` environment variable is set to `queue` by default. The Redis connection is automatically configured from the `REDIS_URL` provided by Heroku.

Refer to the [Heroku n8n tutorial](https://docs.n8n.io/hosting/server-setups/heroku/) and [Queue Mode documentation](https://docs.n8n.io/hosting/scaling/queue-mode/) for more information.

If you have questions after trying the tutorials, check out the [forums](https://community.n8n.io/).
