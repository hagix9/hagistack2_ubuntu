hagistack2 for ubuntu
=====================
OpenStackのバージョンLibertyをインストールするAnsibleのPlaybookです。  
また、外部ライブラリにopenstack-ansible-modules( https://github.com/openstack/openstack-ansible )を利用しています。

出来ること
----------
* Keysotneのインストール
* Glanceのインストール
* Novaのインストール
* Cinderのインストール
* Glanceへのイメージ登録
* Neutronのインストール
* Ceilometerのインストール

まだ出来ないこと
----------------
早く出来るようにします。  

* Fwaas,VPNaaSの設定、Horizonの画面反映
* CinderのバックエンドのNFS対応
* Cinderのループバックデバイス対応(今はVGとしてVolume用サーバに ``cinder-volumes`` が作成されている前提)
* Proxy対応(一部だけ対応)
* 他のコンポーネントのインストール

環境
----
OpenStackをインストールするサーバはUbuntu15.10です。Ubuntu14.04でも大丈夫しれませんが未確認です。  
インストール時にCinder用ボリューム(cinder-volumes)を確保作成していない場合は ``http://docs.openstack.org/developer/kolla/cinder-guide.html`` を参照して作成して下さい。
またOpenStackをインストールするサーバはインストールまでは必要ないですがKVMが利用できる環境でお願いします。
Qemuでも動きますが遅いです。
Ubuntu14.04の場合はリポジトリを追加するようにしています。
自分自身にもインストール出来ますがなるべく別の方がいいと思います。  

* Ansibleが動作するサーバ(別にUbuntuである必要はありません。なるべく新しいAnsibleを利用してください。)
* OpenStackをインストールするサーバ(Ubuntu15.10(14.04)がインストールされているサーバ1台以上、Ansible実行サーバからsshでパスワード無しでログイン出来るようにしておく。)
* インターネットに接続可能な環境（HTTP プロキシ使用可能）

ネットワーク環境
------------------------------
最低限NIC1枚あれば大丈夫です。  

 1. NIC1枚でNeutronを利用する場合のインターフェース設定

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
        address 192.168.122.50
        netmask 255.255.255.0
        network 192.168.122.0
        gateway 192.168.122.1
        dns-nameservers 192.168.122.1
        broadcast 192.168.122.255
    ```

 2. NIC複数枚でNeutronを利用する場合のインターフェース設定

    ``br-ex`` と対応付ける ``eth0`` はインターネットなどに出て行く外部インターフェースを指定します。  
    外部インターフェースはインターフェースが起動する設定だけしておきます。  
    ここでは ``eth0`` になっています。  

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
        address 192.168.122.51
        netmask 255.255.255.0
        network 192.168.122.0
        broadcast 192.168.122.255
        gateway 192.168.122.1
        dns-nameservers 192.168.122.1

    ```

利用方法
--------

 1. ツールのチェックアウト

    AnsibleのPlaybookを実行するサーバにツールをチェックアウトします。
    ライブラリを他のものから使わせてもらっているのでそれもチェックアウトします。

    ```
    git clone https://github.com/hagix9/hagistack2_ubuntu.git
    cd hagistack2_ubuntu
    svn export https://github.com/openstack/openstack-ansible/trunk/playbooks/library library
    ```

 2. 実行ホストの設定

    OpenStackのインストールするサーバのホスト名、IPアドレス、ログインユーザ、Sudoのパスワードを設定します。  
    ホスト名だけでなくIPアドレスを設定するのは各インストール先サーバの ``nova.conf`` に各サーバ毎のIPアドレスを設定する方法がそれしかわからなかったので設定が必要です。

    全てのコンポーネントを一台にインストールする場合
    ------------------------------------------------
    ControlサーバグループとComputeサーバグループに同じサーバを1台だけ設定します。  
    ホスト名、IPアドレスなどは適宜変更してください。
    
    ```
    [openstack_ctl]
    192.168.122.50 ansible_ssh_host=192.168.122.50 ansible_ssh_user=stack ansible_sudo_pass=stack
    
    [openstack_compute]
    192.168.122.50 ansible_ssh_host=192.168.122.50 ansible_ssh_user=stack ansible_sudo_pass=stack
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
    192.168.122.50 ansible_ssh_host=192.168.122.50 ansible_ssh_user=stack ansible_sudo_pass=stack
    
    [openstack_compute]
    192.168.122.51 ansible_ssh_host=192.168.122.51 ansible_ssh_user=stack ansible_sudo_pass=stack
    192.168.122.52 ansible_ssh_host=192.168.122.52 ansible_ssh_user=stack ansible_sudo_pass=stack
    192.168.122.53 ansible_ssh_host=192.168.122.53 ansible_ssh_user=stack ansible_sudo_pass=stack
    
    #[openstack_volume]
    #192.168.122.54 ansible_ssh_user=stack ansible_sudo_pass=stack
    ```
    
 3. 変数の設定
    
    最低限設定する必要する項目は以下です。  
    ``group_vars/all`` が変数設定のファイルです。
    大体OpenStackでの設定項目と同じ変数名にしてあるつもりなので変更する場合もそんなに困らないはずです。
    
    1.ControllerノードのIPアドレス
    ```
    controller_ext_ip: 192.168.122.50
    controller_int_ip: 192.168.122.50
    ```

    2.外部ネットワークの設定(ゲートウェイ,セグメント,フローティングIP)
    
    ```
    gateway: 192.168.122.1
    subnet: 192.168.122.0/24
    ip_pool_start: 192.168.122.151
    ip_pool_end: 192.168.122.200
    ```
    
    3.Adminユーザのパスワード
    
    ```
    admin_password: secrete
    ```
    
    4.オペレーションユーザのパスワード
    
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
    そのままの場合はネットワークなどはstackユーザで作成されているのでそちらを利用して下さい。
    
 6. (CUI)Openstackの利用方法  
    
    コマンドラインでも利用出来ます。
    
    1.Controlサーバへログイン  
    
    オペレーションを行うユーザは ``operate_user`` で設定したものになります。
    変更していなければstackです。
    
    コマンドをOPENRCを利用して行う場合はコンフィグを読み込ませます。

    ```
    ssh stack@[ControlサーバのIP]
    . ./generic01-openrc.sh
    ```

    os-client-configを利用する場合は環境変数で読み込ませるか、コマンド利用時に ``--os-cloud stack`` などとして利用します。コンフィグは ``.config`` の中に設定します。

    ```
    export OS_CLOUD=stack
    ```

    openstackコマンドをエイリアスに設定しておいた方が楽かもしれません。

    ```
    alias os='openstack'
    ```
    
    2.インスタンスの起動
    
    flavorは ``openstack flavor list`` で確認出来ます。  
    imageは ``opensatck image list`` で確認できます。 
    security_groupの設定はHorizonのほうが楽かもしれません。
    以下のコマンドではdefaultを利用します。  
    keypairはツールのデフォルトで設定されるものを組み込みます。  
    ツールでのデフォルトではUbuntu15.10を利用出来るようにしています。  
    ``roles/glance_image/vars/main.yml`` のコメントを外せば他にも利用可能なイメージがあります。  
    ``http://docs.openstack.org/ja/image-guide/image-guide.pdf`` を参照すればイメージの作成方法が詳しく載っています。
    利用するネットワークを指定して起動します。  

    ```
    NETWORK_ID=`neutron net-list | grep sharednet1 | awk '{print $2}'`
    nova boot --flavor 1 --image ubuntu-14.04-x86_64 --security_group default --nic net-id=$NETWORK_ID --key-name mykey Ubuntu14.04_001
    ```

    最後に ``neutron`` の ``L3ネットワーク`` の場合です。  
    利用するネットワークを指定して起動します。  

    ```
    INT_NET_ID=`openstack network list | grep internal_network01 | awk '{ print $2 }'`
    openstack server create  --flavor 1 --image ubuntu-15.10-x86_64 --security-group default --key-name mykey --nic net-id=$INT_NET_ID ubuntu01
    ```
    
    3.インスタンスへのログイン  
    IPアドレスを確認してログインします。    
    フローティングIPを付与していない場合は少し面倒です。
    ``openstack server list`` でIPの確認を行い ``ip netns`` でsnatのIDを確認します。
    Ubuntuの場合とCentOSなどでログインユーザが違います。
    ここではSSHのキーペアを利用してログインします。   
    
    ```
    openstack server list
    ip netns
    ip netns exec snat-4373b9ed-00b6-4770-9c8d-3faab0f6ca98 ssh -i mykey ubuntu@10.10.10.10
    ip netns exec snat-4373b9ed-00b6-4770-9c8d-3faab0f6ca98 ssh -i mykey cloud-user@10.10.10.10
    ```

    フローティングIPは以下のようにして付与します。
    WEBUIで付与したほうが楽です。
    openstackコンフィグではneutronのポート確認などにまだ対応していないみたいです。

    ```
    . /home/stack/generic01-openrc.sh
    SERVER_NAME=ubuntu01
    EXT_NET=external_network01
    neutron floatingip-create $EXT_NET
    neutron floatingip-list
    DEVICE_ID=$(openstack server list | grep $SERVER_NAME | awk '{ print $2 }')
    PRIVATE_IP=$(openstack server list | grep $SERVER_NAME | awk '{print $8}' | awk -F= '{print $2}')
    PORT_ID=$(neutron port-list -- --device_id $DEVICE_ID | grep $PRIVATE_IP | awk '{ print $2 }')
    FLOATING_IP=$(neutron floatingip-list | egrep -v "\+|floating" | head -1 | awk '{print $5}')
    FLOATING_ID=$(neutron floatingip-list | grep $FLOATING_IP | awk '{ print $2 }')
    neutron floatingip-associate $FLOATING_ID $PORT_ID
    ```

    ログインは普通にSSH出来るようになります。
    ```
    openstack server list
    ip netns
    ssh -i mykey ubuntu@10.10.10.10
    ssh -i mykey cloud-user@10.10.10.10
    ```

パスワードでログイン出来るようにする場合は以下のようにファイルを作成してインスタンスを起動します。

    ```
    vi cloud_init

    #cloud-config
    password: pass
    chpasswd: { expire: False }
    ssh_pwauth: True

    INT_NET_ID=`openstack network list | grep internal_network01 | awk '{ print $2 }'`
    openstack server create  --flavor 1 --image ubuntu-15.10-x86_64 --security-group default --user-data cloud_init --key-name mykey --nic net-id=$INT_NET_ID ubuntu01

    あと、サーバを再起動したりした場合メモリが足りないとrabbitmqとmemcachedが起動していない場合があります。 起動しておきます。

    ```
    systemctl start rabbitmq-server
    systemctl start memcached
    ```

    以上です。  

    まずはOpenStackを利用してみたいって場合くらいには対応出来るかなと思います。  

