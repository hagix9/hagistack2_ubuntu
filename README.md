hagistack2 for ubuntu
=====================
OpenStackのバージョンIcehouseをインストールするAnsibleのPlaybookです。  
また、外部ライブラリにopenstack-ansible-modules( https://github.com/lorin/openstack-ansible-modules )を利用しています。

出来ること
----------
* Keysotneのインストール
* Glanceのインストール
* Novaのインストール
* Cinderのインストール
* Glanceへのイメージ登録
* Neutronのインストール(Flat、L3モード)

まだ出来ないこと
----------------
早く出来るようにします。  

* Heatのインストール
* Ceilometerのインストール(動作が怪しいので要調査)
* Troveのインストール
* CinderのバックエンドのNFS対応
* Cinderのループバックデバイス対応(今はVGとしてVolume用サーバに ``cinder-volumes`` が作成されている前提)
* ComputeのKVM以外のバックエンド対応(LXC)
* コンポーネント毎のログ出力設定(debug,verbose)
* Glanceへ登録する他イメージ対応(CoreOSくらいは)
* 各コンポーネントのDBシンク実行時のライブラリ利用
* Proxy対応(Glanceへ登録する際しか対応していないのでapt時、Openstackのコマンド利用時に対応する必要)

環境
----
OpenStackをインストールするサーバはUbuntu14.04でも大丈夫しれませんが未確認です。  
今のところKVMが利用できる環境でおねがいします。
Ubuntu14.04の場合はリポジトリを追加するようにしています。
自分自身にもインストール出来ますがなるべく別の方がいいと思います。  

* Ansibleが動作するサーバ(別にUbuntuである必要はありません。なるべく新しいAnsibleを利用してください。)
* OpenStackをインストールするサーバ(Ubuntu15.10がインストールされているサーバ1台以上、Ansible実行サーバからsshでパスワード無しでログイン出来るようにしておく。)
* インターネットに接続可能な環境（HTTP プロキシ使用可能）

ネットワーク環境
------------------------------
最低限NIC1枚あれば大丈夫です。  

 1. ``nova-network`` を利用する場合のインターフェース設定

    テナント別にネットワークを設定するといったことは出来ません。  
    そういった要件が無ければインスタンスの起動が早いことやトラブルが少ないことなどもあり便利です。  
    但し、次のバージョンで ``nova-network`` は存在しないかもしれません。
    ``group_vars/all`` の ``int_nic: eth0`` の ``eth0`` だけ環境にあわせてください。

 2. NIC1枚でNeutronを利用する場合のインターフェース設定

    OpenStackインストール前にNetwork、ComputeノードになるマシンへOpenVswitchをインストールしインターフェースの設定を行っておきます。  

    ```
    apt-get install openvswitch-switch -y
    ovs-vsctl add-br br-int
    ovs-vsctl add-br br-ex
    ovs-vsctl add-port br-ex eth0
    vi /etc/network/interfaces

    auto eth0
    iface eth0 inet manual
        up ip link set dev $IFACE up
        down ip link set dev $IFACE down

    auto br-ex
    iface br-ex inet static
        address 192.168.10.50
        netmask 255.255.255.0
        network 192.168.10.0
        gateway 192.168.10.1
        dns-nameservers 192.168.10.1
        broadcast 192.168.10.255
    ```

 3. NIC複数枚でNeutronを利用する場合のインターフェース設定

    OpenVswitchの設定は先にしておく必要がありませんがツールがまだ対応していないので今のところは先に設定しておきます。  
    ``br-ex`` と対応付ける ``eth0`` はインターネットなどに出て行く外部インターフェースを指定します。  
    外部インターフェースはインターフェースが起動する設定だけしておきます。  
    ここでは ``eth0`` になっています。  
    ``br-int`` は仮想マシン同士が利用するネットワークです。Neutronの ``ml2_conf.ini`` で設定したIPのインターフェースで利用されます。

    ```
    apt-get install openvswitch-switch -y
    ovs-vsctl add-br br-int
    ovs-vsctl add-br br-ex
    ovs-vsctl add-port br-ex eth0

    vi /etc/network/interfaces

    auto eth0
    iface eth0 inet manual
        up ip link set dev $IFACE up
        down ip link set dev $IFACE down


    auto eth1
    iface eth1 inet static
        address 192.168.10.51
        netmask 255.255.255.0
        network 192.168.10.0
        broadcast 192.168.10.255
        gateway 192.168.10.1
        dns-nameservers 192.168.10.1

    ```

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
    
    コンポーネントをContorlサーバ一台、Computeサーバ複数台に分けてインストールする場合
    ----------------------------------------------------------------------------------
    Controlサーバグループに1台、Computeグループにインストールする台数分設定します。  
    ホスト名、IPアドレスなどは適宜変更してください。  
    CinderのVolume用ホストをControlサーバと別にする場合は ``sites.yml`` の変更をしてください。  
    コメントしてあるので分かると思います。
    またそのままだとControlサーバにもComputeコンポーネントをインストールするようになっています。  
    こちらもControlサーバにComputeコンポーネントが必要なければ ``sites.yml`` の変更をしてください。  
    その場合は、 ``Nova Compute Install`` の箇所を ``openstack_compute`` だけにします。
    
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
    
 3-1. 変数の設定(nova-network)
    
    最低限設定する必要する項目は以下です。  
    ``group_vars/all`` が変数設定のファイルです。
    大体OpenStackでの設定項目と同じ変数名にしてあるつもりなので変更する場合もそんなに困らないはずです。
    
    1.ControllerノードのIPアドレス
    ```
    controller_int_ip: 192.168.10.50
    ```
    2.nova-networkを利用するように設定  

    network_typeを変更します。  
    外部向けIPアドレスの範囲も設定します。  
 
    
    ```
    network_type: nova-network
    #network_type: neutron-flat
    #network_type: neutron-l3
    ```
    
    3.インスタンスの外部接続用アドレス範囲
    
    ```
    ranges: 192.168.10.112/28
    ```
    
    4.Adminユーザのパスワード
    
    ```
    admin_password: secrete
    ```
    
    5.一般ユーザのパスワード
    
    ```
    generic_password01: secrete
    ```

 3-2. 変数の設定(Neutron Flat(L2のみのネットワーク構成))
    
    最低限設定する必要する項目は以下です。  
    ``group_vars/all`` が変数設定のファイルです。
    大体OpenStackでの設定項目と同じ変数名にしてあるつもりなので変更する場合もそんなに困らないはずです。
    
    1.ControllerノードのIPアドレス
    ```
    controller_int_ip: 192.168.10.50
    ```
    
    2.neutronを利用するように設定  

    network_typeを変更します。  
    外部向けIPアドレスの範囲も設定します。  
 
    
    ```
    #network_type: nova-network
    network_type: neutron-flat
    #network_type: neutron-l3
    ip_pool_start: 192.168.10.151
    ip_pool_end: 192.168.10.200
    ```
    
    3.Adminユーザのパスワード
    
    ```
    admin_password: secrete
    ```
    
    4.一般ユーザのパスワード
    
    ```
    generic_password01: secrete
    ```
 3-3. 変数の設定(Neutron L3(ルータを利用したL3ネットワーク構成))
    
    最低限設定する必要する項目は以下です。  
    ``group_vars/all`` が変数設定のファイルです。
    大体OpenStackでの設定項目と同じ変数名にしてあるつもりなので変更する場合もそんなに困らないはずです。
    
    1.ControllerノードのIPアドレス
    ```
    controller_int_ip: 192.168.10.50
    ```
    
    2.neutronを利用するように設定  

    network_typeを変更します。  
    変更した行の下あたりのネットワーク設定も適宜変更してください。  
    ``internal_network01``  側のネットワーク設定は内部接続向けのネットワークなので好きなNWセグメントを指定してください。  
    ``external_network01``  側のネットワーク設定は外部接続向けのネットワークなのでインターネットに接続するセグメントを指定してください。  
 
    
    ```
    #network_type: nova-network
    #network_type: neutron-flat
    network_type: neutron-l3
    ```
    
    3.Adminユーザのパスワード
    
    ```
    admin_password: secrete
    ```
    
    4.一般ユーザのパスワード
    
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
    
    1.Controlサーバへログイン  
    
    オペレーションを行うユーザは ``operate_user`` で設定したものになります。
    
    ```
    ssh ControlサーバのIP
    su - stack
    . ./generic01-openrc.sh
    ```
    
    2.インスタンスの起動
    
    flavorは ``nova flavor-list`` で確認出来ます。  
    imageは ``nova image-list`` で確認できます。 
    security_groupの設定はHorizonのほうが楽かもしれません。以下のコマンドではdefaultを利用します。  
    keypairはツールでデフォルトで設定されるものを組み込みます。  
    ツールでのデフォルトではUbuntu14.04を利用出来るようにしています。  
    ``roles/glance_image/vars/main.yml`` のコメントを外せば他にも利用可能なイメージがあります。  
    ``http://docs.openstack.org/ja/image-guide/image-guide.pdf`` を参照すればイメージの作成方法が詳しく載っています。
    
    ```
    nova boot --flavor 1 --image ubuntu-14.04-x86_64 --security_group default --key-name mykey Ubuntu14.04_001
    ```

    上記は ``nova-network`` の時の起動方法で以下は ``neutron`` の ``Flatネットワーク`` の場合です。  
    利用するネットワークを指定して起動します。  

    ```
    NETWORK_ID=`neutron net-list | grep sharednet1 | awk '{print $2}'`
    nova boot --flavor 1 --image ubuntu-14.04-x86_64 --security_group default --nic net-id=$NETWORK_ID --key-name mykey Ubuntu14.04_001
    ```

    最後に ``neutron`` の ``L3ネットワーク`` の場合です。  
    利用するネットワークを指定して起動します。  

    ```
    INT_NET_ID=`neutron net-list | grep internal_network01 | awk '{ print $2 }'`
    nova boot --flavor 1 --image ubuntu-14.04-x86_64 --security_group default --nic net-id=$INT_NET_ID --key-name mykey ubuntu01
    ```
    
    3.インスタンスへのログイン  
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

