# Überauth Yandex

> Yandex OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Yandex Developer Console](https://console.developers.yandex.com/home).

1. Add `:ueberauth_yandex` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_yandex, "~> 0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_yandex]]
    end
    ```

1. Add Yandex to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        yandex: {Ueberauth.Strategy.Yandex, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Yandex.OAuth,
      client_id: System.get_env("YANDEX_CLIENT_ID"),
      client_secret: System.get_env("YANDEX_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/yandex

Or with options:

    /auth/yandex?scope=login%3Aemail+login%3Ainfo+login%3Aavatar

By default the requested scope is "email". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    yandex: {Ueberauth.Strategy.Yandex, [default_scope: "login:email login:info"]}
  ]
```

To guard against client-side request modification, it's important to still check the domain in `info.urls[:website]` within the `Ueberauth.Auth` struct if you want to limit sign-in to a specific domain.

## Credits

Sponsored by [JetRockets](http://www.jetrockets.pro).

![JetRockets](http://jetrockets.pro/jetrockets-white.png)

## License

Please see [LICENSE](https://github.com/romul/ueberauth_yandex/blob/master/LICENSE) for licensing details.
