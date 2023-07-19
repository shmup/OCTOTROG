set dotenv-load

default: run

attach:
    screen -c $IRSSI_CONFIG -r $SCREEN_SESSION

run:
    @$RUNNER
    @just attach

run-dev:
    @$RUNNER octo_irssi_dev.config
    @just attach

backup:
    @$BACKER

install-modules:
    @# Check if CPAN is installed
    @if ! command -v cpan > /dev/null 2>&1; then \
        @echo "CPAN is not installed. Please install it first."; \
        exit 1; \
    fi

    @# Check if DBI and DBD::SQLite modules are installed
    @perl -e "use DBI;" 2>/dev/null || DBI_NOT_FOUND=1
    @perl -e "use DBD::SQLite;" 2>/dev/null || SQLITE_NOT_FOUND=1

    @# If any module is not installed, install them
    @if [ -n "$$DBI_NOT_FOUND" ] || [ -n "$$SQLITE_NOT_FOUND" ]; then \
        echo "Some modules not found. Installing..."; \
        cpan install DBI DBD::SQLite; \
    fi

    @# Check if the modules are installed successfully
    @perl -e "use DBI;" 2>/dev/null || { \
        echo "Failed to install DBI module. Please check the error above."; \
        exit 1; \
    }
    @perl -e "use DBD::SQLite;" 2>/dev/null || { \
        echo "Failed to install DBD::SQLite module. Please check the error above."; \
        exit 1; \
    }

    @echo "DBI and DBD::SQLite modules are installed successfully."
