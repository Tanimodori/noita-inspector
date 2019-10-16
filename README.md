# noita-inspector

A noita spell extractor by Tanimodori

Noita-inspector creates fake context for injecting spells and uses reflected metatable to dump spell specs into .json file. Data can be used in wikis, so you guys can dump spells automatically.

Translations can be find in `data/translations/common.csv`, sprite path are also dumped.

This inspector only works for simple attribute manipulations, i.e. not accurate for "c.some_attribute = c.other_attribute"

## Usage

Note: You new to unpack data.wak of Noita first.

See usage by executing

`lua.exe noita_inspector.lua -h`

## License

MIT License
