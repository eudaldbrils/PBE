
require "gtk3"
require "./nfc"
require 'thread'



	
class Finestra < Gtk::Window
	@@label 
	@@r
	@@uid
	@@blanc=Gdk::RGBA::new(1.0,1.0,1.0,1.0)
	@@blau= Gdk::RGBA::new(0,0,1.0,1.0)
	@@vermell=Gdk::RGBA.new(1.0,0,0,1.0)
	@@canvi
	def initialize
		#En aquest bloc de comandes inicialitzem i importem el fitxer css
		css_provider = Gtk::CssProvider.new
		style_provider = Gtk::StyleProvider::PRIORITY_USER
		css_provider.load(:data=> File.read("diseny.css"))
	
		#Aquí inicialitzem el widget finestra
		@@uid=""
 		window = Gtk::Window.new("inter")
		window.set_size_request(250,250)
		window.set_border_width(10)
		window.set_window_position(:CENTER)
		window.style_context.add_provider(css_provider,style_provider)

		#Creem una graella que ens serà útil per posar el botó
		grid = Gtk::Grid.new
		grid.set_row_homogeneous(true)
		grid.set_column_homogeneous(true)
		window.add(grid)
		
		#Inicialitzo el text que apareixerà a la pantalla quan estiguem esperant el uid(la pantalla inicial)
		font = Pango::FontDescription.new('20')
		@@label = Gtk::Label.new("Passi la targeta",{:use_underline =>false})
		@@label.override_font(font)
		@@label.override_background_color(:normal,@@blau)
		@@label.override_color(:normal,@@blanc)
		
		#Creeo el botó i l'inicialitzo amb el seu estat inicial
		button = Gtk::Button.new(:label =>"Clear")
		button.style_context.add_provider(css_provider, style_provider)
		grid.attach(button,0,6,5,1)
		grid.attach( @@label,0,0,5,5)
		window.show_all
		
		#Creo un objecte de la clase Rfid i arrenco el fil
		@@r = Rfid.new
		fil
		
		#Escric les instruccions que cal fer quan es polsi el botó clear
		button.signal_connect("clicked") do
			#si ja s'ha mostrat el uid llavors tornem a demanar-lo canviant de pantalla
			#i tornant a cridar el thread fil
			if @@uid != ""
				puts "canvia"
				@@label.override_background_color(:normal,@@blau)
				@@label.set_text("Passi la targeta")
				fil
				
			end
		end
		
	end
	
	#Funció fil, consisteix en un thread que llegira el uid
	def fil
		t = Thread.new{
			llegeix
			puts "acabo el thread"
			t.exit
		}
	end
	
	#Funció  que llegiex l'uid
	def llegeix
			@@uid = @@r.read_uid
			#Punt clau del codi, delegar la tasca a canvipantalles
			GLib::Idle.add{canvipantalles}
			puts "surto"
	end

	#Funció que canvia la pantalla i la posa de color vermell i mostra l'uid
	def canvipantalles
		if @@uid != ""
			puts "entro"
			@@label.override_background_color(:normal,@@vermell)
			@@label.text=@@uid.upcase		
			puts "surto"
		end
		
	end
end


#main del codi
f = Finestra.new
	
Gtk.main
