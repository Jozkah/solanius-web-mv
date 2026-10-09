# Solanius memory viewer

Local web panel for **Solanius Universal**. Loopback only (`127.0.0.1:9000`). Nothing is hosted on a server.

Original UI/relay: [Jozkah/web-mv](https://github.com/Jozkah/web-mv) (MIT), adapted for Universal.

The overlay **script is on the Solanius script market** (open source). This repo is only the viewer you run on your PC.

## Setup

1. Install [Bun](https://bun.sh).
2. Double-click `start-web-mv.bat` (or `build-release.bat` then `run.bat`).
3. Leave that window open. Open **http://127.0.0.1:9000**.
4. In Universal, load the memory viewer script from the market. Console should say `relay connected`. Refresh the browser — status **ext up**.

Do not load another script that uses `ws::` at the same time.

## License

MIT. Original work © Jozkah. Relay fallback and Solanius theming are adaptations.
