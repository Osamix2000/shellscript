#!/bin/bash

# CentOS7: devtoolset-12 導入スクリプト
# - Springdale SCL repoが生きている時だけ repo を作成
# - 導入前に centos-sclo-rh / centos-sclo-sclo を一時的に無効化
# - 成功/失敗どちらでも終了時に元の状態へ復元
# - 導入後は springdale-scl repo を無効化(enabled=0)

set -e

REPO_NAME="springdale-scl"
REPO_FILE="/etc/yum.repos.d/${REPO_NAME}.repo"
BASEURL="https://ftp.riken.jp/Linux/springdale/SCL/7/x86_64/"
REPOCHECK_URL="${BASEURL}repodata/repomd.xml"

SCL_RH_FILE="/etc/yum.repos.d/CentOS-SCLo-scl-rh.repo"
SCL_SCL_FILE="/etc/yum.repos.d/CentOS-SCLo-scl.repo"

BACKUP_DIR="/tmp/devtoolset12_repo_backup.$$"

cleanup() {
	set +e

	# 作成したrepoは無効化して残す(消したいなら rm -f に変更)
	if [ -f "$REPO_FILE" ]; then
		awk '
			BEGIN { in_repo=0 }
			/^\[/ {
				if ($0=="[springdale-scl]") {
					in_repo=1
				} else {
					in_repo=0
				}
			}
			in_repo && $0 ~ /^enabled=/ { print "enabled=0"; next }
			{ print }
		' "$REPO_FILE" > "${REPO_FILE}.tmp" && mv -f "${REPO_FILE}.tmp" "$REPO_FILE"
	fi

	# SCLo repoは元に戻す(バックアップがある場合のみ)
	if [ -d "$BACKUP_DIR" ]; then
		if [ -f "$BACKUP_DIR/CentOS-SCLo-scl-rh.repo" ]; then
			cp -f "$BACKUP_DIR/CentOS-SCLo-scl-rh.repo" "$SCL_RH_FILE"
		fi
		if [ -f "$BACKUP_DIR/CentOS-SCLo-scl.repo" ]; then
			cp -f "$BACKUP_DIR/CentOS-SCLo-scl.repo" "$SCL_SCL_FILE"
		fi
		rm -rf "$BACKUP_DIR"
	fi
}
trap cleanup EXIT INT TERM

echo "repo生存確認: ${REPOCHECK_URL}"

if command -v curl >/dev/null 2>&1; then
	if ! curl -fsL --max-time 10 "$REPOCHECK_URL" >/dev/null; then
		echo "エラー: リポジトリが見つからない/到達不可のため中止"
		exit 1
	fi
elif command -v wget >/dev/null 2>&1; then
	if ! wget -q --spider --timeout=10 "$REPOCHECK_URL"; then
		echo "エラー: リポジトリが見つからない/到達不可のため中止"
		exit 1
	fi
else
	echo "エラー: curl/wgetが無いためリポジトリ生存確認が出来ない"
	exit 1
fi

echo "repoファイル作成: ${REPO_FILE}"

cat <<EOF > "$REPO_FILE"
[${REPO_NAME}]
name=Springdale SCL 7
baseurl=${BASEURL}
enabled=1
gpgcheck=0
EOF

# 既存SCLo repoをバックアップして一時的に無効化
mkdir -p "$BACKUP_DIR"

if [ -f "$SCL_RH_FILE" ]; then
	cp -f "$SCL_RH_FILE" "$BACKUP_DIR/CentOS-SCLo-scl-rh.repo"
	awk '
			BEGIN { in_section=0 }
			/^\[centos-sclo-rh\]$/ { in_section=1; print; next }
			/^\[/ { in_section=0; print; next }
			in_section && $0 ~ /^enabled=/ { print "enabled=0"; next }
			{ print }
	' "$SCL_RH_FILE" > "${SCL_RH_FILE}.tmp"
	mv -f "${SCL_RH_FILE}.tmp" "$SCL_RH_FILE"
fi

if [ -f "$SCL_SCL_FILE" ]; then
	cp -f "$SCL_SCL_FILE" "$BACKUP_DIR/CentOS-SCLo-scl.repo"
	awk '
			BEGIN { in_section=0 }
			/^\[centos-sclo-sclo\]$/ { in_section=1; print; next }
			/^\[/ { in_section=0; print; next }
			in_section && $0 ~ /^enabled=/ { print "enabled=0"; next }
			{ print }
	' "$SCL_SCL_FILE" > "${SCL_SCL_FILE}.tmp"
	mv -f "${SCL_SCL_FILE}.tmp" "$SCL_SCL_FILE"
fi

echo "yum キャッシュクリア"

yum clean all

echo "yum キャッシュ再生成"

yum makecache --disablerepo="*" --enablerepo="${REPO_NAME}"

echo "devtoolset-12 インストール"

yum install devtoolset-12 devtoolset-12-gcc devtoolset-12-gcc-c++ devtoolset-12-binutils --disablerepo="*" --enablerepo="${REPO_NAME}"

echo ""
echo "従来 gcc バージョン"

gcc --version

echo ""
echo "devtoolset-12 gcc バージョン"

scl enable devtoolset-12 "gcc --version"

echo ""
echo "完了"

