# Pinpoint
This is a web app that allows you to view the location of your device and share your location with friends. It's essentially a clone of [Apple's Find My](https://www.apple.com/icloud/find-my/) that is written in [Elixir](https://elixir-lang.org/) and uses the [Phoenix web framework](https://www.phoenixframework.org/).

## Screenshot
The blue marker represents your current location, and the pink marker represents a friend.

![Example showing markers on a map representing you and a friend.](screenshots/example.png)

## Requirements

* Elixir 1.15 installed.
* A PostgreSQL database running on port 5432. To follow the instructions in the [Try it out](#try-it-out) section, both the database username and password must be "postgres" (without quotes).

## Try it out

You can test it out for yourself by cloning this repo, opening a terminal inside the new directory, and running the commands below. This assumes that you have the necessary requirements described in the [section above](#requirements).
```
mix setup
mix phx.server
```
Now the server should be running on port 4000. If you've never used Elixir before, you can kill the server by pressing Ctrl+C twice.
