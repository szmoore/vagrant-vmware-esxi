require 'log4r'
require 'net/ssh/simple'

module VagrantPlugins
  module ESXi
    module Action
      # This action will list all the snapshots
      class SnapshotInfo
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_vmware_esxi::action::snapshot_info')
        end

        def call(env)
          suspend(env)
          @app.call(env)
        end

        def suspend(env)
          @logger.info('vagrant-vmware-esxi, snapshot_info: start...')

          # Get config.
          machine = env[:machine]
          config = env[:machine].provider_config

          @logger.info("vagrant-vmware-esxi, snapshot_info: machine id: #{machine.id}")
          @logger.info("vagrant-vmware-esxi, snapshot_info: current state: #{env[:machine_state]}")

          if env[:machine_state].to_s == 'not_created'
           env[:ui].info I18n.t('vagrant_vmware_esxi.vagrant_vmware_esxi_message',
                                message: 'Cannot snapshot_info in this state')
          else

            Net::SSH::Simple.sync(
              user:     config.esxi_username,
              password: config.esxi_password,
              port:     config.esxi_hostport,
              keys:     config.esxi_private_keys,
            ) do

              r = ssh config.esxi_hostname,
                  "vim-cmd vmsvc/snapshot.get #{machine.id} 2>&1 | "\
                  "sed 's/Get Snapshot:/ /g' | "\
                  "grep -v "\
                  "-e 'Snapshot Id ' "\
                  "-e 'Snapshot Desciption ' "\
                  "-e 'Snapshot State '"

              snapshotinfo = r.stdout
              if r.exit_code != 0
                raise Errors::ESXiError,
                      message: "Unable to list snapshots:\n"\
                               "  #{allsnapshots}\n#{r.stderr}"
              end

              env[:ui].info I18n.t('vagrant_vmware_esxi.vagrant_vmware_esxi_message',
                                   message: "#{snapshotinfo}")
            end
          end
        end
      end
    end
  end
end
