#!/bin/bash
set -e
source ${GITLAB_RUNTIME_DIR}/functions

[[ $DEBUG == true ]] && set -x

case ${1} in
  app:init|app:start|app:sanitize|app:rake)

    initialize_system
    configure_gitlab
    configure_gitlab_shell
    configure_gitlab_pages
    configure_nginx

    case ${1} in
      app:start)
        cd ${GITLAB_INSTALL_DIR}
        migrate_database
        rm -rf ${GITLAB_HOME}/tmp/supervisord/supervisor.sock
        exec /usr/bin/supervisord -c ${SUPERVISOR_CONF}
        ;;
      app:init)
        cd ${GITLAB_INSTALL_DIR}
        migrate_database
        ;;
      app:sanitize)
        sanitize_datadir
        ;;
      app:rake)
        shift 1
        cd ${GITLAB_INSTALL_DIR}
        execute_raketask $@
        ;;
    esac
    ;;
  app:help)
    echo "Available options:"
    echo " app:start        - Starts the gitlab server (default)"
    echo " app:init         - Initialize the gitlab server (e.g. create databases, compile assets), but don't start it."
    echo " app:sanitize     - Fix repository/builds directory permissions."
    echo " app:rake <task>  - Execute a rake task."
    echo " app:help         - Displays the help"
    echo " [command]        - Execute the specified command, eg. bash."
    ;;
  *)
    exec "$@"
    ;;
esac
