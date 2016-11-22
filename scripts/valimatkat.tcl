# V�limatkat v1.3.2
# matka.tcl http://fury.fi/~joep/eggdrop-scripts.php
# Ilmoittaa kaupunkien v�limatkan sek� (optiona) matkan kestoajan.
#
# Muokannut mm. [tonttu �t gospelnet piste �f ii]
# Uusin versio: http://bot.gospelnet.fi/?matka
#
# K�ytt� : !matka <kaupunki 1> <kaupunki 2> <nopeus>
#          /msg botnick matka <kaupunki 1> <kaupunki 2> <nopeus>
#
# Esimerkkej� : !matka espoo helsinki
#               !matka tampere oulu 230 
#
# Lukema 230 (ei pakollinen) on keskinopeus km/h, jolloin skripta palauttaa
# my�s matkan kestoajan.
#
# Haku tehd��n osoitteesta http://www.tieh.fi/valim2.htm
#
# Feel free to use & modify, but please keep the info about
# original author
#
#   joep@fury.fi
#
#############################################################################

# Konfiguroi seuraavat :

# Kanavat, joilla botin sallitaan tai ei sallita matkatietoja n�ytt�v�n
# T�h�n siis vain kanavia joilla botti itse on!
#
# J�t� sallitut_kanavat_matka tyhj�ksi jos haluat ett� toimii automaattisesti
# kaikilla kanavilla joilla botti on (oletuksena n�in).
#
# Jos kanavan nimess� on skandeja niin j�t� sallitut_kanavat_matka tyhj�ksi,
# skandit voivat aiheuttaa ongelmia ja t�ll� voi kiert�� moisen ongelman.
#
# Esimerkki1: sallitaan vain kanavat #pastilli ja #peelotus
# set sallitut_kanavat_matka { pastilli peelotus }
# set kielletyt_kanavat_matka { }
#
# Esimerkki2: sallitaan kaikki paitsi #palle ja #tumplaus
# set sallitut_kanavat_matka { }
# set kielletyt_kanavat_matka{ palle tumplaus }
#
# Vakio-optioilla (molemmat tyhji�) on sallittu kaikki kanavat.
# Optio kielletyt_kanavat_matka ei vaikuta msg-kyselyihin.
#
set sallitut_kanavat_matka { }
set kielletyt_kanavat_matka { }

# vaaditaanko ett� kysyj� on sallituilla kanavilla (ks lista yll�) ett�
# toimii messagella
# 1 = vaaditaan
# 0 = ei vaadita (kaikki IRCiss� olijat voivat kysell�!)
set vaaditaanko_kanavalle_matka 0

# komento jolla skripta aktivoituu
set matka_command "matka"

# Ilmoitustyyppi
# 1 = botti kertoo NOTICE:na
# 0 = botti kertoo "normaali" kommenttina (PRIVMSG)
set botti_ilmtyyppi_matka 0

# Ilmoitetaanko public haun j�lkeen mahdollisuus k�ytt�� messagea
# 1 = ilmoitetaan
# 0 = ei ilmoiteta
set ilmoitetaanko_public_matka 0

# Bindit
# Vakiona toimii public kysely (kanavalla) jos userilla +f (friend) lippu.
# Jos haluat ett� kaikilla toimii publiccina, laita pelkk� - (ks. msg-rivit mallia).
#
bind pub - !$matka_command pub_matka
bind msg - $matka_command msg_matka
bind msg - !$matka_command msg_matka

############################################################################
#                                                                          #
# �l� muuta mit��n t�st� eteenp�in                                         #
#                                                                          #
############################################################################

proc msg_matka {nick uhost hand lause} {
	global floodi sallitut_kanavat_matka vaaditaanko_kanavalle_matka
	global botti_ilmtyyppi_matka
	putlog [encoding convertfrom identity "$nick $uhost matka $lause"]
	set on_channel 0

	if { [llength $sallitut_kanavat_matka] == 0 } {
			# tutkitaan onko kyselij� samalla kanavalla kuin botti
			foreach kanava [channels] {
				if { [onchan $nick "$kanava"] } { set on_channel 1 }
				}
		} else {
			# katsotaan sallituiden kanavien perusteella
			foreach idx $sallitut_kanavat_matka {
				if { [onchan $nick "#$idx"] } { set on_channel 1 }
				}
		}

	# jos ei vaadita kanavalle niin joka tapauksessa ok
	if { $vaaditaanko_kanavalle_matka == 0 } { set on_channel 1 }

	if { $on_channel } {
		hae_matka $lause
		if { $botti_ilmtyyppi_matka == 0 } {
				putserv [encoding convertfrom identity "PRIVMSG $nick :$floodi"]
			} else {
				putserv [encoding convertfrom identity "NOTICE $nick :$floodi"]
			}
		}
}

proc pub_matka {nick uhost hand chan lause} {
	global floodi botnick sallitut_kanavat_matka kielletyt_kanavat_matka
	global botti_ilmtyyppi_matka ilmoitetaanko_public_matka

	# poistutaan jos kanava on kiellettyjen listalla
	if { ([lsearch -exact $kielletyt_kanavat_matka [string trimleft [string tolower $chan] "#"]] != -1) } {
		return 0
		}

	set channel [string trimleft [strlwr $chan] "#"]

	# jatketaan jos kysely on tullut sallitulla kanavalla tai
	# sallitut_kanavat_matka parametri on tyhj�
	# (kaikki kanavat sallittu)
	if { ([lsearch -exact $sallitut_kanavat_matka $channel] != -1) || ([llength $sallitut_kanavat_matka] == 0)} {
		hae_matka $lause
		if { $botti_ilmtyyppi_matka == 0 } {
				putserv [encoding convertfrom identity "PRIVMSG $chan :$floodi"]
				if { $ilmoitetaanko_public_matka == 1 } { putserv [encoding convertfrom identity "PRIVMSG $nick :Toimii my�s /msg $botnick matka <kaupunki 1> <kaupunki 2>"] }
			} else {
				putserv [encoding convertfrom identity "NOTICE $chan :$floodi"]
				if { $ilmoitetaanko_public_matka == 1 } { putserv [encoding convertfrom identity "NOTICE $nick :Toimii my�s /msg $botnick matka <kaupunki 1> <kaupunki 2>"] }
			}
		}
}

proc hae_matka { lause } {
global floodi

	set lause_list [split $lause " "]

	set lahto [strupr [string range [lindex $lause_list 0] 0 0]]
	append lahto [strlwr [string range [lindex $lause_list 0] 1 end]]

	set paamaara [strupr [string range [lindex $lause_list 1] 0 0]]
	append paamaara [strlwr [string range [lindex $lause_list 1] 1 end]]

	set nopeus [lindex $lause_list 2]

	if { $lahto == $paamaara } {
		set floodi "0 km, eh ?"
		return
		}

	# erikoistapauksia
	if { $lahto == "Heinola" } { append lahto " (yhdistetty)" }
	if { $paamaara == "Heinola" } { append paamaara " (yhdistetty)" }
	if { $lahto == "Porvoo" } { append lahto " (yhdistetty)" }
	if { $paamaara == "Porvoo" } { append paamaara " (yhdistetty)" }
	if { $lahto == "Lohja" } { append lahto " (yhdistetty)" }
	if { $paamaara == "Lohja" } { append paamaara " (yhdistetty)" }
	if { $lahto == "Suomussalmi" } { append lahto ", kko." }
	if { $paamaara == "Suomussalmi" } { append paamaara ", kko." }
	if { $lahto == "Utsjoki" } { append lahto ", Utsjoki" }
	if { $paamaara == "Utsjoki" } { append paamaara ", Utsjoki" }
	if { $lahto == "V�rtsil�" } { append lahto " kko" }
	if { $paamaara == "V�rtsil�" } { append paamaara " kko" }

	# lis�� erikoistapauksia [t o n t t u �t gospelnet piste �f ii]
	array set aliases {
		"Kaaresuvanto" "Enonteki�, Kaaresuvanto"
		"Kilpisj�rvi" "Enonteki�, Kilpisj�rvi"
		"Kivilompolo" "Enonteki�, Kivilompolo"
		"Palojoensuu" "Enonteki�, Palojoensuu"
		"Inari" "Inari kko"
		"Ivalo" "Inari, Ivalo"
		"N��t�m�" "Inari, N��t�m�"
		"Raja-jooseppi" "Inari, Raja-Jooseppi"
		"Repojoki" "Inari, Repojoki"
		"S�yn�tsalo" "Jyv�skyl�, S�yn�tsalo"
		"Palokka" "Jyv�skyl�n mlk, Palokka"
		"Tikkakoski" "Jyv�skyl�n mlk, Tikkakoski"
		"Vaajakoski" "Jyv�skyl�n mlk, Vaajakoski"
		"Kaipola" "J�ms�, Kaipola"
		"Haapam�ki" "Keuruu, Haapam�ki"
		"Vartius" "Kuhmo, Vartius, raja"
		"Riistavesi" "Kuopio, Riistavesi"
		"Nuijamaa" "Lappeenranta, Nuijamaa"
		"Lappi" "Lappi tl"
		"Lievestuore" "Laukaa, Lievestuore"
		"Koli" "Lieksa, Koli"
		"Otava" "Mikkeli, Otava"
		"Raippaluoto" "Mustasaari, Raippaluoto"
		"Meri-pori" "Pori, Meri-Pori"
		"Meltaus" "Rovaniemen mlk, Meltaus"
		"Pirttikoski" "Rovaniemen mlk, Pirttikoski"
		"Vuoj�rvi" "Sodankyl�, Vuoj�rvi"
		"Vuotso" "Sodankyl�, Vuotso"
		"Sukeva" "Sonkaj�rvi, Sukeva"
		"�mm�nsaari" "Suomussalmi, �mm�nsaari"
		"Tenhola" "Tammisaari, Tenhola"
		"Tuuri" "T�ys�, Tuuri"
		"Karigasniemi" "Utsjoki, Karigasniemi"
		"Nuorgam" "Utsjoki, Nuorgam"
		"Kalanti" "Uusikaupunki, Kalanti"
		"Vaalimaa" "Virolahti, Vaalimaa, raja"
		"Niirala" "V�rtsil�, Niirala, raja"
		"Konginkangas" "��nekoski, Konginkangas"
	}
	foreach {written toreplace} [array get aliases] {
		if {$lahto == $written} { set lahto $toreplace }
		if {$paamaara == $written} { set paamaara $toreplace }
	}

	if { [string first "�" $lahto] == 0 } {
		set lahtoapu "�"
		append lahtoapu [string range $lahto 1 end]
		set lahto $lahtoapu
		}
	if { [string first "�" $paamaara] == 0 } {
		set paamaaraapu "�"
		append paamaaraapu [string range $paamaara 1 end]
		set paamaara $paamaaraapu
		}

	set haku "HTTP/1.1\n"
	append haku "Accept: */*\n"
	append haku "Referer: http://www.tiehallinto.fi\n"
	append haku "Accept-Language: fi\n"
	append haku "Content-Type: application/x-www-form-urlencoded\n"
	append haku "Accept-Encoding: gzip, deflate\n"
	append haku "User-Agent: Mozilla/4.0 (compatible; MSIE 4.01; Windows 98)\n"
	append haku "Host: alk.tiehallinto.fi\n"
	append haku "Content-Length: 57\n"
	append haku "Proxy-Connection: Keep-Alive\n"
	append haku "Pragma: No-Cache\n\n"
	append haku "MIST�="
	append haku $lahto
	append haku "&MIHIN="
	append haku $paamaara
	append haku "&NOPEUS="
	if { $nopeus == "" } {
			append haku "80"
		} else {
			append haku $nopeus
		}
	append haku "\n"

	set portti 80
	set site "alk.tiehallinto.fi"
	set url "/cgi-bin/pq9.cgi"

	set sock [socket $site $portti]
	puts $sock "POST $url $haku"
	puts $sock "GET $url HTTP/1.1"
	puts $sock "connection: close"
	puts $sock "host: $site\n"
	flush $sock
	set foo [read $sock]
	close $sock

	set foo [split $foo \n]

	set valimatka 0

	foreach i $foo {
		set valistart [string first "V�limatka on" $i]
		set matkaaikastart [string first "Ajoaika on" $i]
		if { $valistart != -1 } {
			set valimatka [string range $i [expr $valistart +13] [expr [string first "km" $i] -2]]
			}
		if { $matkaaikastart != -1 } {
			set matkaaika [string range $i [expr $matkaaikastart +11] [expr [string first "min" $i] -2]]
			if { $matkaaika == "" } {
				set matkaaika "60"
				}
			}
		}

	if { $valimatka == 0 || $valimatka == 2 } {
			set floodi "V�limatka $lahto - $paamaara 0km. Virheelliset kaupunkinimet (tai ei tuettu)?"
		} else {
			if { $nopeus == "" } {
					set floodi "V�limatka $lahto - $paamaara on $valimatka km"
				} else {
					if { $nopeus > 199 } {
							set floodi "V�limatka $lahto - $paamaara on $valimatka km, ajoaika $nopeus km/h matalalentomeiningill� $matkaaika minuuttia"
						} else {
							set floodi "V�limatka $lahto - $paamaara on $valimatka km, ajoaika $nopeus km/h vauhdilla $matkaaika minuuttia"
						}
				}
		}
}

putlog [encoding convertfrom identity "Script loaded: \002V�limatkat 1.3.2\002"]
