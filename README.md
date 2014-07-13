hagistack2 for ubuntu
=====================
OpenStackのバージョンIcehouseをインストールするAnsibleのPlaybookです。  
今はnova-networkにしか対応していないのでNeutronを利用するのは無理です。  
また、外部ライブラリにopenstack-ansible-modules( https://github.com/lorin/openstack-ansible-modules )を利用しています。

出来ること
----------
* Keysotneのインストール
* Glanceのインストール
* Novaのインストール
* Cinderのインストール
* Glanceへのイメージ登録

まだ出来ないこと
----------------
早く出来るようにします。  

* Neutronのインストール
* Heatのインストール
* Ceilometerのインストール
* Troveのインストール
* CinderのバックエンドのNFS対応
* Cinderのループバックデバイス対応(今はVGとしてVolume用サーバに ``cinder-volumes`` が作成されている前提)
* ComputeのKVM以外のバックエンド対応(LXC、Qemu)
* コンポーネント毎のログ出力設定(debug,verbose)
* Glanceへ登録する他イメージ対応(CoreOSくらいは)
* 各コンポーネントのDBシンク実行時のライブラリ利用
* Proxy対応(Glanceへ登録する際しか対応していないのでapt時、Openstackのコマンド利用時に対応する必要)

環境
----
OpenStackをインストールするサーバはUbuntu12.04でも大丈夫しれませんが未確認です。  
今のところKVMが利用できる環境でおねがいします。
Ubuntu12.04の場合はリポジトリを追加するようにしています。
自分自身にもインストール出来ますがなるべく別の方がいいと思います。  

* Ansibleが動作するサーバ(別にUbuntuである必要はありません。なるべく新しいAnsibleを利用してください。)
* OpenStackをインストールするサーバ(Ubuntu14.04がインストールされているサーバ1台以上、Ansible実行サーバからsshでパスワード無しでログイン出来るようにしておく。)
* インターネットに接続可能な環境（HTTP プロキシ使用可能）

ネットワーク環境(nova-network)
------------------------------
今のところnova-networkにしか対応していないのでNIC1枚あれば大丈夫です。


利用方法
--------

1. ツールのチェックアウト 
AnsibleのPlaybookを実行するサーバにツールをチェックアウトします。

 ```
 git clone https://github.com/hagix9/hagistack2_ubuntu.git
 cd hagistack2_ubuntu
 git submodule init
 git submodule update
 ```

2. 実行ホストの設定
OpenStackのインストールするサーバのホスト名、IPアドレス、ログインユーザ、Sudoのパスワードを設定します。  
ホスト名だけでなくIPアドレスを設定するのは各インストール先サーバの ``nova.conf`` に各サーバ毎のIPアドレスを設定する方法がそれしかわからなかったので設定が必要です。

全てのコンポーネントを一台にインストールする場合
------------------------------------------------
Controlサーバグループに1台だけ設定します。  
ホスト名、IPアドレスなどは適宜変更してください。

```
[openstack_ctl]
192.168.10.50 ansible_ssh_host=192.168.10.50 ansible_ssh_user=stack ansible_sudo_pass=stack
```

コンポーネントをコン一台にインストールする場合
------------------------------------------------
Controlサーバグループに1台、Computeグループにインストールする台数分設定します。  
ホスト名、IPアドレスなどは適宜変更してください。  
CinderのVolume用ホストをControlサーバと別にする場合は ``sites.yml`` の変更をしてください。  
コメントしてあるので分かると思います。

```
[openstack_ctl]
192.168.10.50 ansible_ssh_host=192.168.10.50 ansible_ssh_user=stack ansible_sudo_pass=stack

[openstack_compute]
192.168.10.51 ansible_ssh_host=192.168.10.51 ansible_ssh_user=stack ansible_sudo_pass=stack
192.168.10.52 ansible_ssh_host=192.168.10.52 ansible_ssh_user=stack ansible_sudo_pass=stack
192.168.10.53 ansible_ssh_host=192.168.10.53 ansible_ssh_user=stack ansible_sudo_pass=stack

#[openstack_volume]
#192.168.10.54 ansible_ssh_user=stack ansible_sudo_pass=stack
```

3. 変数の設定
最低限設定する必要する項目は以下です。  
``group_vars/all`` が変数設定のファイルです。
大体OpenStackでの設定項目と同じ変数名にしてあるつもりなので変更する場合もそんなに困らないはずです。

  1. ControllerノードのIPアドレス
  ```
  controller_int_ip: 192.168.10.50
  ```

  2. インスタンスの外部接続用アドレス範囲
  ```
  ranges: 192.168.10.112/28
  ```

  3. Adminユーザのパスワード
  ```
  admin_password: secrete
  ```

  4. 一般ユーザのパスワード

  ```
  generic_password01: secrete
  ```

4. Ansibleの実行
後は、Ansibleを実行すればインストールが実行されます。

```
ansible-playbook -i hosts sites.yml
```

5. (WebUI)Openstackの利用方法
``http://ControlサーバのIPアドレス/horizon`` にブラウザで接続することでOpenstackのHorizonが利用出来ます。  
ツールでテナントが2つ用意してますので ``admin`` ユーザ、 ``stack`` ユーザでログイン出来ますのでログインして色々いじってみてください。 

6. (CUI)Openstackの利用方法
コマンドラインでも利用出来ます。

  1. Controlサーバへログイン
  オペレーションを行うユーザは ``operate_user`` で設定したものになります。
  
  ```
  ssh ControlサーバのIP
  su - stack
  . generic01-openrc.sh
  ```

  2. インスタンスの起動
  flavorは ``nova flavor-list`` で確認出来ます。 
  imageは ``nova image-list`` で確認できます。 
  security_groupの設定はHorizonのほうが楽かもしれません。以下のコマンドではdefaultを利用します。
  keypairはツールでデフォルトで設定されるものを組み込みます。
  CentOS6.5を起動しますが利用するイメージはSELinux、SSHのログインはパスワードでのログイン不可などちょっと不便なイメージです。
  ツールでのデフォルトではUbuntu14.04とCentOS6.5が利用出来るようにしています。
  ``roles/glance_image/vars/main.yml`` のコメントを外せば他にも利用可能なイメージがあります。

  ```
  nova boot --flavor 1 --image centos6.5 --security_group default --key-name mykey centos6.5_001
  nova boot --flavor 1 --image ubuntu-14.04-x86_64 --security_group default --key-name mykey Ubuntu14.04_001
  ```

  3. インスタンスへのログイン
  IPアドレスを確認してログインします。  
  フローティングIP(外部から接続出来るIP)は自動的に付与する設定にしています。
  Ubuntuの場合とCentOSでログインユーザが違います。SSHのキーペアを利用してログインします。  

  ```
  nova list
  ssh -i mykey ubuntu@192.168.10.113
  ssh -i mykey cloud-user@192.168.10.113
  ```

以上です。  
とりあえずOpenStackを利用するって場合くらいには対応出来るかなと思います。  

