package cmd

import (
	"github.com/andig/evcc/api"
	"github.com/andig/evcc/server"
	"github.com/andig/evcc/util"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// chargerCmd represents the charger command
var chargerCmd = &cobra.Command{
	Use:   "charger [name]",
	Short: "Query configured chargers",
	Run:   runCharger,
}

func init() {
	rootCmd.AddCommand(chargerCmd)
}

func runCharger(cmd *cobra.Command, args []string) {
	util.LogLevel(viper.GetString("log"), viper.GetStringMapString("levels"))
	log.INFO.Printf("evcc %s (%s)", server.Version, server.Commit)

	// load config
	conf := loadConfigFile(cfgFile)

	// setup mqtt
	if conf.Mqtt.Broker != "" {
		configureMQTT(conf.Mqtt)
	}

	if err := cp.configureChargers(conf); err != nil {
		cp.Close() // cleanup any open sessions
		log.FATAL.Fatal(err)
	}

	defer cp.Close() // cleanup on exit

	chargers := cp.chargers
	if len(args) == 1 {
		arg := args[0]
		chargers = map[string]api.Charger{arg: cp.Charger(arg)}
	}

	d := dumper{len: len(chargers)}
	for name, v := range chargers {
		d.DumpWithHeader(name, v)
	}
}
