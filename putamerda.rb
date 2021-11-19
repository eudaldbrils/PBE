require 'json'
require 'http'
require "gtk3"
require "./nfc"
require 'thread'
require 'facets/timer'




#j = '{"a": 1, "b": 2}'
#puts JSON.parse(j)
	
class Finestra < Gtk::Window
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
	
	
	def initialize
		@@css_provider = Gtk::CssProvider.new
		@@style_provider = Gtk::StyleProvider::PRIORITY_USER
		@@css_provider.load(:data=> File.read("project.css"))
		
		@@window = Gtk::Window.new("inter")
		@@window.set_size_request(250,250)
		@@window.set_border_width(10)
		@@window.set_window_position(:CENTER)
		@@window.signal_connect("delete-event") { |_widget| Gtk.main_quit }
		@@window.style_context.add_provider(@@css_provider,@@style_provider)
		
		@uid=" "
		
		
		#@@grid1 = Gtk::Grid.new
		#@@grid1.set_row_homogeneous(true)
		#@@grid1.set_column_homogeneous(true)
		
		@@grid2 = Gtk::Grid.new
		@@grid2.set_row_homogeneous(true)
		@@grid2.set_column_homogeneous(true)
		@@grid2.set_row_spacing(10)
		
		#font = Pango::FontDescription.new('20')
		@@label1 = Gtk::Label.new("Please login with your university card",{:use_underline =>false})
		@@label1.set_name("labelprincipal")
		@@label1.style_context.add_provider(@@css_provider,@@style_provider)

		@@label2 = Gtk::Label.new("",{:use_underline =>false})
		@@label2.set_name("labelnomusuari")
		@@label2.style_context.add_provider(@@css_provider,@@style_provider)

		#@@label2.override_font(font)
		#@@label1.override_font(font)
		
		@@grid2.attach(@@label1,0,0,1,1)
		@@window.add(@@grid2)
		
		@@r = Rfid.new
		
		@@bole=true
		@@bole2 = true
		
		@@display = Gtk::TextView.new
		@@display.set_editable(true)
		@@display.set_cursor_visible(true)
		@@display.show
		
		@@button = Gtk::Button.new(:label =>"Logout")
		@@button.style_context.add_provider(@@css_provider,@@style_provider)

		@@button1 = Gtk::Button.new(:label =>"Enviar query")
		@@button1.style_context.add_provider(@@css_provider,@@style_provider)
	
		
		
	
		@@button.signal_connect("clicked") do
			@@button.set_sensitive(false)
			remove_grid
			@@timer.stop
			@@timer.reset
			@@timer.start
			self.finestra1			
		end
		@@button1.signal_connect("clicked") do
				remove_grid				
				@@str=""
				@@database = ""
				@@timer.stop
				@@timer.reset
				@@timer.start
				@@str=self.coger_mensaje_y_borrar(@@display.buffer)
				puts @@str
				var = @@str.split("?")
				@@database = var[0]
				connexio_server
				
			
				
		end
		
		
	end
	
		def start_timer
			puts "timer"
			@@timer = Timer.new(10){
				puts "hola"
				#@@timer.reset
				remove_grid
				finestra1
			}
			
			@@timer.start

		end
	
		def which_database
			array = []
			if @@database == "timetable"
				array = @@timetables
			elsif @@database =="marks"
				array = @@marks
			elsif @@database == "tasks"
				array = @@tasks
			
			end
		
			return array	
	
		end
		
		def remove_grid
			
			i = 0
			j = 0 
			label = @@grid2.get_child_at(0,4)
			if label!=nil
				@@grid2.remove(label)
			end 			
			
			while @@grid2.get_child_at(0,j+5)!=nil
				i=0
				while @@grid2.get_child_at(i,j+5)!=nil
					label = @@grid2.get_child_at(i,j+5)
					@@grid2.remove(label)
					i = i+1
				end 
				j = j+1
				
				
			end 

			
		
		end
	
		def taules(resp)
			
			array = which_database
			label = Gtk::Label.new(@@database,{:use_underline =>false})
			label.set_name("labelvermell")
			label.style_context.add_provider(@@css_provider,@@style_provider)
			@@grid2.attach(label,0,4,1,1)	
			array.each.with_index do|line,i|
				label = Gtk::Label.new(line,{:use_underline =>false})
				label.set_name("labeltitols")
				label.style_context.add_provider(@@css_provider,@@style_provider)
				@@grid2.attach(label,i,5,1,1)	
			end
			resp.each_line.with_index do|line,j|
				jsond = JSON.parse(line)
				array.each.with_index do|line2,i|
					label = Gtk::Label.new(jsond[line2],{:use_underline =>false})
					if j%2==0
						label.set_name("labelpar")
					else 
						label.set_name("labelimpar")

					end
					label.style_context.add_provider(@@css_provider,@@style_provider)
					@@grid2.attach(label,i,j+6,1,1)
				
				end
			end
			
			@@window.show_all
			puts "hola profe"
		end 
	
		def espera_resposta
			if @@database == "marks"
				@@str<<"&student_id="<<@@uid.upcase
			end
			resp = HTTP.get("http://192.168.1.135:8000/course_manager.php?"<<@@str).to_s
			puts"rebo dada"
			puts resp
			GLib::Idle.add{taules(resp)}

		
		end
	
		def connexio_server
			serv = Thread.new{
				espera_resposta
			}
		
		end
	
		def coger_mensaje_y_borrar(buf)
			iter1=buf.start_iter
			iter2=buf.end_iter
			missatge=buf.get_text(iter1,iter2,false)
			buf.delete(iter1,iter2)
			return missatge
		end
		
		
		def llegeix
				@@uid = ""
				@@uid = @@r.read_uid
				puts @@uid
				body = HTTP.get("http://192.168.1.135:8000/course_manager.php?students?uid="<<@@uid).to_s
				var = JSON.parse(body)
				puts var
				#Punt clau del codi, delegar la tasca a canvipantalles
				GLib::Idle.add{canvipantalles(var["uid"],var["name"])}
		end
			def fil
			t = Thread.new{
				llegeix
				puts "mato"
				
			}
		end
		
			def canvipantalles(str_uid,name)
			puts "canvipantalles"
			if @@uid.upcase == str_uid#falta completar
				self.finestra2(name)
			else
				self.finestra1
			end 
			
			
			puts "surto"
			
		end
			def finestra1
			#S'hauria d'arreglar(CODI MOLT BRUT)
			if @@bole==false
				#@@grid2.remove(@@label1)
				@@grid2.remove(@@button)
				@@grid2.remove(@@button1)
				@@grid2.remove(@@display)
				@@grid2.remove(@@label2)
				#@@window.remove(@@grid2)
				@@label1.text="Please login with your university card"
			end
			@@label1.set_name("labelprincipal")
			@@label1.style_context.add_provider(@@css_provider,@@style_provider)
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
			#@@window.remove(@@label1)
			@@label1.text = "Welcome " #disseny css per aplicar
			@@label2.text = name
			@@label1.set_name("labelwelcome")
			@@label1.style_context.add_provider(@@css_provider,@@style_provider)
			#@@grid2.attach(@@label1,0,0,1,1)
			@@display.set_expand(false)
			@@grid2.attach(@@button,3,0,1,1)
			@@grid2.attach(@@display, 0,1,4,1)
			@@grid2.attach(@@button1, 0,3,1,1)
			@@grid2.attach(@@label2,2,0,1,1)
			#@@window.add(@@grid2)
			@@window.show_all

			
		end
		
	

	

  
end


#main del codi
f = Finestra.new
f.finestra1
Gtk.main
