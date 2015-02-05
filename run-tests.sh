#!/bin/bash
#
# This runs the testsuite
#
# If you have a local webserver call this script with it's URL. Otherwise the
# php dev server is used and that slows down tests a lot.
#

startdir="$(dirname "$0")"
url=""
use_php_dev_server=0

if (($#>0)); then
	url="$1"
fi


if [[  -z "$url" ]]; then
	port=23115
	url="http://127.0.0.1:$port/index.php"
	use_php_dev_server=1
fi

cd "$startdir"

test -d system || exit 1
test -d application || exit 1
test -f run-tests.sh || exit 1

# prepare
cat <<EOF >application/config/database-testsuite.php || exit 1
<?php
\$db['default']['dbprefix'] = "testsuite-prefix-";
EOF

if ((use_php_dev_server)); then
	php -S 127.0.0.1:$port &
	server_pid=$!

	while ! curl -s "$url" >/dev/null; do
		sleep 0.2;
	done
fi

testpath="application/tests"
tests=($testpath/test_*.php)
tests=(${tests[@]#$testpath\/})
tests=(${tests[@]%.php})

#  run tests
php index.php tools update_database
prove -ve "php index.php tools test $url" "${tests[@]}"
php index.php tools drop_all_tables_using_prefix

# cleanup
if ((use_php_dev_server)); then
	kill $server_pid
fi
rm -f $startdir/application/config/database-testsuite.php
