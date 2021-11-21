require 'json'
require 'http'
require "gtk3"
require "./nfc"
require 'thread'
require 'facets/timer'
require "./lcd"



#j = '{"a": 1, "b": 2}'
#puts JSON.parse(j)
	
class Finestra < Gtk::Window
	#INICIALITZACIO DE LES VARIABLES QUE NECESSITAREM
	@@button 
	@@button1
	@@r
	@@uid
	#@@blanc=Gdk::RGBA::new(1.0,1.0,1.0,1.0)
	#@@blau= Gdk::RGBA::new(0,0,1.0,1.0)
	#@@vermell=Gdk::RGBA.new(1.0,0,0,1.0)
	@@canvi
	#@@grid1
	@@grid2
	@@label1
	@@label2
	@@label3
	@@window
	@@bole
	@@bole2
	@@display
	@@tete= false
	@@str
	@@timetables= ["day","hour","subject", "room"]
	@@tasks = ["date","subject", "name"]
	@@marks = ["subject", "name", "mark"]
	@@database
	@@timer
	@@lcd
	
	
	def initialize
		#CONSTRUCTOR
		
		#DEFINICIO DE CSS 
		@@css_provider = Gtk::CssProvider.new
		@@style_provider = Gtk::StyleProvider::PRIORITY_USER
		@@css_provider.load(:data=> File.read("project.css"))
		
		
		#CREACIÓ DE LA FINESTRA
		@@window = Gtk::Window.new("inter")
		@@window.set_border_width(10)
		@@window.set_window_position(:CENTER)
		
		#BOTO CREUETA DE LA FINESTRA
		@@window.signal_connect("delete-event") { |_widget| Gtk.main_quit }
		@@window.style_context.add_provider(@@css_provider,@@style_provider)
		
		#@uid=" "
		
		#CRACIO DEL OBJECTE LCD QUE ENS PERMETRA MOSTRAR MISSATGES PER PANTALLA
		@@lcd = Lcd.new 
		
		
		#@@grid1 = Gtk::Grid.new
		#@@grid1.set_row_homogeneous(true)
		#@@grid1.set_column_homogeneous(true)
		
		#CRACIO DE GRID ON TREBALLAREM AMB LA INGENIERIA DE WIDGETS
		@@grid2 = Gtk::Grid.new
		@@grid2.set_row_homogeneous(true)
		@@grid2.set_column_homogeneous(true)
		@@grid2.set_row_spacing(10)
	
		
		#CREACIO DEL LABEL DE TEXT DE LA FINESTRA INICIAL
		#font = Pango::FontDescription.new('20')
		@@label1 = Gtk::Label.new("Please login with your university card",{:use_underline =>false})
		@@label1.set_name("labelprincipal")
		@@label1.style_context.add_provider(@@css_provider,@@style_provider)
		
		#CREACIO DEL LABEL ON GUARDAREM L'USUARI ACTUAL 
		@@label2 = Gtk::Label.new("",{:use_underline =>false})
		@@label2.set_name("labelnomusuari")
		@@label2.style_context.add_provider(@@css_provider,@@style_provider)
		
		#CREACIO DEL LABEL QUE DONA LA BENVINGUDA A L'USUARI
		@@label3 = Gtk::Label.new("Welcome",{:use_underline =>false})
		@@label3.set_name("labelwelcome")
		@@label3.style_context.add_provider(@@css_provider,@@style_provider)
		

		#@@label2.override_font(font)
		#@@label1.override_font(font)
		
		#AFEGIM EL LABEL DE LA PANTALLA 1
		@@grid2.attach(@@label1,0,0,1,1)
		@@window.add(@@grid2)
		
		#CREEM OBJECTE QUE ENS PERMET LLEGIR LA TARGETA NFC 
		@@r = Rfid.new
		
		#BOLEANS QUE ENS PERMETRAN LA GESTIO DEL CANVI DE FINESTRES
		@@bole=true
		@@bole2 = true
		
		#CREACIO DE LA BARRA DE TEXT QUE ENS PERMETRA ENVIAR QUERRIES
		@@display = Gtk::TextView.new
		@@display.set_editable(true)
		@@display.set_cursor_visible(true)
		@@display.show
		
		#BOTO LOGOUT
		@@button = Gtk::Button.new(:label =>"Logout")
		@@button.style_context.add_provider(@@css_provider,@@style_provider)

		#BOTO ENVIAR QUERRY
		@@button1 = Gtk::Button.new(:label =>"Enviar query")
		@@button1.style_context.add_provider(@@css_provider,@@style_provider)
	
		
		
		#BOTO LOGOUT
		@@button.signal_connect("clicked") do
			@@button.set_sensitive(false)
			#BORREM LES TAULES QUE TENIM CREADES
			remove_grid
			
			#PAREM EL TIMER JA QUE NOMES VOLEM QUE CORRI QUAN ESTIGUI A LA FINESTRA 2
			@@timer.stop
			@@timer.reset
			#@@timer.start
			
			#PASSEM A LA FINESTRA 1
			self.finestra1			
		end
		
		#GESTIO DEL BOTO DE ENVIAR QUERRY
		@@button1.signal_connect("clicked") do
				#BORREM ELS TAULES EN CAS QUE N'HI HAGIN
				remove_grid
				
				#RESETEJEM LES VARIABLES
				@@str=""
				@@database = ""
			
				#ARRANQUEM EL TIMER
				@@timer.stop
				@@timer.reset
				@@timer.start
				
				#LLEGIM EL QUE ENS TENIM AL DISPLAY
				@@str=self.coger_mensaje_y_borrar(@@display.buffer)
				puts @@str
				
				#SEPAREM EL MISSATGE PER ? EN CAS QUE N'HI HAGI
				var = @@str.split("?")
				
				#SEMPRE GUARDEM A LA PRIMERA POSICIO DE DATABASE LA POSICIO 0 DE VAR 
				@@database = var[0]
			
				#ENS CONNECTEM AL SERVIDOR
				connexio_server
				
			
				
		end
		
		
	end
		#FUNCIO START_TIMER: ARRANQUEM UN COMPTADOR, UN COP PASSI UN TEMPS DETERMINAT HEM DE PASSAR A FINESTRA 1
		def start_timer
			puts "timer"
			
			#DEFINIM EL QUE HA DE FER EL TIMER UN COP S'ACABI EL CRONOMETRE
			@@timer = Timer.new(20){
				puts "hola"
				#@@timer.reset
				
				#BORREM LES TAULES
				remove_grid
				
				#PASSEM A FINESTRA 1
				finestra1
			}
			#SI CRIDEM LA FUNCIO I NO PASSI EL TIMEOUT S'HA DARRENCAR
			@@timer.start

		end
		
		#FUNCIO WICH_DATABASE: FUNCIO QUE ENS PERMET SABER QUIN PARAMETRE VOLEM TRACTAR
		def which_database
			
			#RECORDEM QUE DATABASE ES LA PRIMERA PARAULA DE LA QUERRY QUE ENVIEM ABANS DE ?
			array = []
			if @@database == "timetable"
				array = @@timetables
			elsif @@database =="marks"
				array = @@marks
			elsif @@database == "tasks"
				array = @@tasks
			
			else  
				#TRACTAMENT D'ERRORS, SI LA @@DATABASE NO ES CAP DE LES TRES OPCIONS DEFINIDES HA DE MOSTAR MISSATGE ERROR
				array = ["Error"]
			
			end
		
			return array	
	
		end
	
		#FUNCIO REMOVE_GRID: FUNCIO QUE ENS BUIDA EL GRID
		
		def remove_grid
			
			i = 0
			j = 0 
			
			#MIREM EL LABEL QUE INSERIM A LA FILA 4 I COL 0 SI NO ES NULL L'HEM DE BORRAR
			label = @@grid2.get_child_at(0,4)
			if label!=nil
				@@grid2.remove(label)
			end 			
			
			#ARA PROCEDIM A BORRAR LA TAULA, MENTRES EXISTEIXIN LABELS A LES FILES SEGUIM
			while @@grid2.get_child_at(0,j+5)!=nil
				
				i=0
				#MENTRES QUDIN LABELS A LA COLUMNA SEGUIM
				
				while @@grid2.get_child_at(i,j+5)!=nil
					label = @@grid2.get_child_at(i,j+5)
					
					#BORREM EL CORRESPONENT LABEL
					@@grid2.remove(label)
					
					#ENS MOVEM DE COLUMNA
					i = i+1
				end 
				#ENS MOVEM DE FILA
				j = j+1
				
				
			end 

			
		
		end
		
		#FUNCIO TAULES: AQUESTA FUNCIO CREE LES TAULES I GESTIONA ERRORS DE QUERRY
		def taules(resp)
			
			array = which_database
			
			#SI LA POSICIO 0 ARRAY ES ERROR AFEGIM UN LABEL VERMELL I EL NOM DE L'ERROR QUE ENS PASSA EL SERVIDOR, EL LABEL APAREIX A LA FILA 4 COL0
			if array[0] == "Error"
				label = Gtk::Label.new(resp,{:use_underline =>false})
				label.set_name("labelvermell")
				label.style_context.add_provider(@@css_provider,@@style_provider)
				@@grid2.attach(label,0,4,1,1)
			else
				#EN CAS QEU NO TINGUEM ERRORS DE QUERRY, AFEGIM UN LABEL QUE A A POS FILA 4 COL 0 DE COLOR VERMELL AMB EL NOM DE LA TAULA QUE ENS MOSTRA
				label = Gtk::Label.new(@@database,{:use_underline =>false})
				label.set_name("labelvermell")
				label.style_context.add_provider(@@css_provider,@@style_provider)
				@@grid2.attach(label,0,4,1,1)	
				
				# RECORREM L'ARRAY I AFEGEIX LA LABELS QUE INDICARAN ELS TITOLS DE LES COLUMNES DE LA TAULA
				array.each.with_index do|line,i|
					label = Gtk::Label.new(line,{:use_underline =>false})
					label.set_name("labeltitols")
					label.style_context.add_provider(@@css_provider,@@style_provider)
					@@grid2.attach(label,i,5,1,1)	
				end
				
				#ARA TRACTEM LO QUE ENS ENVIA EL SERVIDOR, PRIMER ANEM MOVENT-NOS PELS SALTS DE L'INEA QUE ENS ENVIEN DES DEL SERVIDOR
				resp.each_line.with_index do|line,j|
					
					#PER A CADA SALT DE LINEA FEM UN JSON.PARSE
					jsond = JSON.parse(line)
					
					#ARA AFEGIREM LES FILES, ARA AL FER EL PARSE TENIM COM UN MAPA 
					array.each.with_index do|line2,i|
						
						#CREEM UN LABEL QUE LI PASSEM PER TEXT LO QUE ENS ENVIA EL SERVIDOR SI LI PASSEM EL TITOL DE LA COLUMNA i
						label = Gtk::Label.new(jsond[line2],{:use_underline =>false})
						
						#PER CANVIAR ELS COLORS DEL LABEL DEPENENT DE LA FILA
						if j%2==0
							label.set_name("labelpar")
						else 
							label.set_name("labelimpar")

						end
						label.style_context.add_provider(@@css_provider,@@style_provider)
						
						#AFEGIM EL LABEL A LA POSICIO COL i FILA j+6
						@@grid2.attach(label,i,j+6,1,1)
					
					end
				end
			end
			@@window.show_all
			puts "hola profe"
		end 

		#FUNCIO ESPERA_RESPOSTA: EN AQUESTA FUNCIO ESPEREM UNA RESPOSTA DEL SERVIDOR I CRIDEM A LA FUNCIO QUE ENS CREARA LES TAULES
		def espera_resposta
			
			#SI LA QUERRY QUE ENVIEM EL PRIMER PARAMETRE ABANS DE ? ES MARKS HEM DE CONCATENAR: marks&student_id=id_actual
			if @@database == "marks"
				@@str<<"&student_id="<<@@uid.upcase
			end
			
			#FEM LA PETICIO AL SERVIDOR
			resp = HTTP.get("http://192.168.4.46:8000/course_manager.php?"<<@@str).to_s
			puts"rebo dada"
			puts resp
			
			#DELEGUEM TASQUES A LA FUNCIO TAULES I LI PASSEM PER PARAMETRE LO QUE REBEM DEL SERVIDOR
			GLib::Idle.add{taules(resp)}

		
		end
		
		#FUNCIO CONNEXIO_SERVER: CREEM UN THREAD I CRIDEM A LA FUNCIO ESPERA_RESPOSTA
		def connexio_server
			serv = Thread.new{
				espera_resposta
			}
		
		end
		
		#FUNCIO COGER_MENSAJE_Y_BORRAR: LI PASSEM PER PARAMETRO EL BUFFER DEL DISPLAY, SIMPLEMENT ENS RETORNA UN STRING AMB EL QUE HEM ESCRIT AL DISPLAY 
		def coger_mensaje_y_borrar(buf)
			iter1=buf.start_iter
			iter2=buf.end_iter
			missatge=buf.get_text(iter1,iter2,false)
			buf.delete(iter1,iter2)
			return missatge
		end
		
		#FUNCIO LLEGEIX: AQUESTA FUNCIO SERVEIX PER LLEGIR UN ID I REBRE UNA RESPOSTA DEL SERVIDOR
		def llegeix
				#INICIALITZEM UID I POSEM EN MARXA EL LECTOR
				@@uid = ""
				@@uid = @@r.read_uid
				puts @@uid
						
				#UN COP HEM LLEGIT PASSEM A FER UNA PETICIO AL SERVIDOR
				body = HTTP.get("http://192.168.4.46:8000/course_manager.php?students?uid="<<@@uid).to_s
				puts body
				
				#SI L'UID QUE HEM LLEGIT NO EXISTEIX A LA BASE DE DADES HEM DE FER LA SEVA GESTIO
				if body== ""
					
					#SOBREESCRIVIM BODY AMB UN STRING BUIT EL QUAL PUGUEM FER UN JSON.PARSE
					body ='{"uid":"","name":""}'

				end
				var = JSON.parse(body)
				puts var
				

				#DELEGUEM LA TASCA AL CANVIPANTALLES 
				GLib::Idle.add{canvipantalles(var["uid"],var["name"])}
		end
	
		#FUNCIO FIL: THREAD QUE CRIDA A LA FUNCIO LLEGEIX 
		def fil
			t = Thread.new{
				llegeix
				puts "mato"
				
			}
		end
		
		#FUNCIO CANVIPANTALLES: FUNCIO ENCARREGADA DEL CANVI DE PANTALLES, LI PASSEM PER PARAMETRES EL UID QUE ENS RETORNA EL SERVIOR I LE NOM DE L'USUARI
		def canvipantalles(str_uid,name)
			puts "canvipantalles"
			
			#SI EL UID QUE HEM LLEGIT CONCORDA AMB EL QUE ENS PASSA EL SERVIDOR PASSEM A FINESTRA2 
			if @@uid.upcase == str_uid#falta completard
				puts "finestra2"
				self.finestra2(name)
			
			else #SI EL UID QUE HEM LLEGIT NO CONCORDA AMB EL QUE HEM PASSAT S'HA D'ESCRIURE UN MISSATGE D'ERROR I QUEDAR-SE A FINESTRA1
				puts "uknown"
				@@lcd.escriure("    Unknown user ")
				finestra1(true)
			end 
			
			
			puts "surto"
			
		end
		
		#FUNCIO FINESTRA1, LI PASSEM PER PARAMETRO UN BOOLEA QUE EN PRINVIPI SERA FALS PERO QUE EL PODEM FER VARIAR
		def finestra1(bole_origin=false)
			
			#SI ES LA ES LA PRIMERA VEGADA QUE ENTREM A FINESTRA 1 NO CAL FER CAP REMOVE
		-	if @@bole==false
				#@@grid2.remove(@@label3)
				@@grid2.remove(@@button)
				@@grid2.remove(@@button1)
				@@grid2.remove(@@display)
				@@grid2.remove(@@label2)
				#@@window.remove(@@grid2)
				
			end
			
			#SI EL BOOLEA QUE HEM PASSAT ES TRUE LLAVORS VOL DIR QUE HI HA HAGUT UN ERROR AL REGISTRE I QUE L'USUARI NO ESTA A LA BASE DE DADES
			if bole_origin == true
				@@lcd.escriure("Unknown user\nPlease login with\n your univerity card")
				@@label1.text = "                   Unknown user:\nplease login with your univerity card"
			else
				#SI EL BOOLEA ES FALSE VOL DI QUE NO HI HA CAP PROBLEMA AMB EL REGISTRE
				@@lcd.escriure("Please login with\n your univerity card")
				@@label1.text = "Please login with your univerity card"
			
			end
			
			@@window.set_size_request(800,500)	
			@@grid2.set_name("grid_fin1")
			@@grid2.style_context.add_provider(@@css_provider,@@style_provider)
			#@@grid2.attach(@@label1,0,0,1,1)
			
			@@label1.set_name("labelprincipal")
			@@bole=false
			@@button.set_sensitive(true)
			#@@label1.override_background_color(:normal,@@blau)
			#@@label1.override_color(:normal,@@blanc)
			
			#@@window.add(@@label1)
			
			#@@grid1.remove(@@button)
			#@@grid1.remove(@@label2)
			
			#@@grid1.attach( @@label1,0,0,5,5)
			@@window.show_all
			
			self.fil
		end
		def finestra2(name)
			start_timer
			
			@@window.set_size_request(800,500)
			#@@grid2.remove(@@label1)
			@@label1.text = "Welcome"
			@@label1.set_name("labelwelcome")
			@@grid2.set_name("grid_fin2")
			@@grid2.style_context.add_provider(@@css_provider,@@style_provider)
			@@lcd.escriure("\n      Welcome\n"<<name)
							
			@@label2.text = name
			
			#@@grid2.attach(@@label3,0,0,1,1)
			@@grid2.attach(@@button,2,0,1,1)
			@@grid2.attach(@@display, 0,1,3,1)
			@@grid2.attach(@@button1, 0,2,1,1)
			@@grid2.attach(@@label2,1,0,1,1)
			al=Gtk::Align.new(2)
            @@label2.set_halign(al)
            @@label2.set_hexpand(true)
			#@@window.add(@@grid2)
			@@window.show_all

			
		end
		
	

	

  
end


#main del codi
f = Finestra.new
f.finestra1
Gtk.main
