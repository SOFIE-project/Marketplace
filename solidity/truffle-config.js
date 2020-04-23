module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration! 
  mocha: {
    reporter: "mocha-multi-reporters",
    reporterOptions: {
      "reporterEnabled": "spec, mocha-junit-reporter",
      "mochaJunitReporterReporterOptions": {
        mochaFile: "../tests/smart_contracts_test_results.xml"
      }
    }
  },
  compilers: {
    solc: {
      version: "0.5.8",
    }
  },
  networks: {
    ganache: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    }
  },
};
  
