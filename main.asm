.data
palabra: .space 8 // Donde se guarda la palabra
suposicion: .space 8 // Donde se guarda la palabra ingresada
mascara: .space 8 // Indica el color de cada caracter de la palabra ingresada

palabras: .space 53 // Buffer que va a contener las palabras. ACTUALIZAR DE ACUERDO AL TAMAÑO DEL ARCHIVO
palabras_size: .int 53 // Tamaño de archivo
palabras_name: .asciz "palabras.txt"

nombre: .space 4 // Nombre del jugador
intentos: .word 4

color_default: .asciz "\033[37m"
color_verde: .asciz "\033[32m"
color_amarillo: .asciz "\033[33m"

prompt: .asciz "Ingrese una palabra de x caracteres: "
mensaje_intentos: .asciz "\nQuedan x intentos.\n"
mensaje_nombre: .asciz "\nFelicidades, Ganaste!\nIngrese su apodo de tres caracteres: "
mensaje_final: .asciz "\nTu puntaje es: "
mensaje_ranking: .asciz "\nEl ranking queda:"
mensaje_jugar: .asciz "\nPerdiste. Seguir jugando? y/n "
eleccion: .byte 0 // Utilizado para guardar la elección sí/no del jugador (y/n)

separador: .space 2 // Separo la sección de mensajes de la de ranking para evitar problemas de escritura en buffers incorrectos

ranking_name: .asciz "ranking.txt"
ranking_size: .int 21 // Tamaño de archivo
// La línea a escribir y el buffer son adyacentes, de modo que estén "encadenados" de la forma en que se van a escribir en el archivo.
linea_ranking: .space 7
buffer_ranking: .space 21

enter: .asciz "\n"

seed: .word 32
const1: .word 1103515245
const2: .word 12345
numero: .word 0

puntaje: .space 2 // Representación ASCII del puntaje

.text
//mostrar_puntaje
//muestra por pantalla el puntaje
//En r0 recibe la direccion de memoria de mensaje_fnial y en r3 la direccion de memoria del puntaje
//no devuelve nada
mostrar_puntaje:
.fnstart
	push { lr }
	bl calcular_letra // r1 --> longitud del mensaje a mostrar

	mov r2,r1 // Length del mensaje
	mov r1,r0 // Mensaje
	bl imprimir

	mov r2, #2 // Length del mensaje
	mov r1, r3 // Mensaje (puntaje)
	bl imprimir

	ldr r1,=enter
	bl imprimir
	pop { lr }
	bx lr
.fnend

//convertirPuntaje:
//Convierte el punta en valor hexa para poder imprimirlo
//En r3 recibe el puntaje y en r0 la direccion
//Te deja en la etiqueta puntaje el valor.
convertirPuntaje:
.fnstart
	push { r0, r1, r2, r3, lr }
	mov r1,#0 // entero
	cicloConvertir:
                 cmp r3, #10 //Comparo si r3(puntaje es menor que 10)
                 blt convertirYSubirAMemoria //si es menor convierte el entero y el resto
                 add r1, #1 //si no es menor le sumo 1 al entero
                 sub r3, #10 // luego le resto 10 al puntaje
                 bal cicloConvertir //vuelve al cilo
        convertirYSubirAMemoria:
                 add r1,#0x30 //aumento 30 en hexa para obtener valor ascii
                 add r3,#0x30
                 strb r1,[r0] //subo a memoria el entero
                 strb r3,[r0,#1]  //subo a memoria el resto
        salir:
        pop { r0, r1, r2, r3, lr }
        bx lr
.fnend

//calcular_puntos:
//Calcula el puntaje segun los intentos restantes que le queda al jugador
//En r0 recibe la cantidad de intentos que le quedan
//En r3 devuelve el puntaje.
calcular_puntos:
.fnstart
        push { r0, r2, r3, lr }
			add r0,#1 //para obtener la cantidad de intentos que quedaban al ganar el juego (en cada ciclo se resta uno)
            mov r2,#0 //para saber cuando termina el ciclo
            mov r3,#0 //coloco el r1 en 0 para colocar el puntaje
            cicloPuntaje:
                cmp r0, r2 // comparo el indice con la cantidad de intentos
                beq salirCicloPuntaje // si son iguales salgo
                add r2, #1 // como no es igual le sumo 1 al indice
                add r3, #5 // le sumo 5 al acumulador
                bal cicloPuntaje
            salirCicloPuntaje:
                ldr r0,=puntaje
                bl convertirPuntaje
        	pop { r0, r2, r3, lr }
       		bx lr
.fnend

//calcular_letra:
// 1) Cuenta la cantidad de letras que tiene la palabra.
// 2) En r0 recibo la direccion de memoria de la palabra
// 3) En r1 obtengo el valor de la cantidad de caracteres de la palabra
calcular_letra:
.fnstart
	push { r3, lr }            // Guardo r3 pq lo utilizo en la subrutina
	mov r1, #0x00              // Contador para contar caracteres
	ciclo:
		ldrb r3, [r0, r1]      // Obtengo el caracter de la posición r1.
		cmp r3, #0x00          // Comparo si la palabra llego a su final.
		beq salirDeLaSubrutina // Si es igual salgo de la subrutina.
		add r1, #1             // si no es igual aumento el contador.
		bal ciclo              // vuelo el ciclo.
	salirDeLaSubrutina:
		pop { r3, lr }
		bx lr                  // Vuelvo al programa
.fnend

//leer_palabra:
// 1) Lee la palabra ingresada por el usuario
// 2) En r1 se necesita la direccion de memoria donde se va guardar esa entrada y en r2 el leng(leng = que se plabra elije automaticamente) de lo que se va ingresar.
// 3) En r3 se devuelve la palabra que ingreso el usuario.
leer_palabra:
.fnstart
	push { r0, r4, r7, lr } // DEBERÍA SER UN NÚMERO PAR DE REGISTROS

	// Imprimir el prompt
	push { r1, r2 }
	ldr r0, =prompt
	bl calcular_letra // r1 --> longitud del prompt
	mov r2, r1 // Longitud del prompt
	mov r1, r0 // Prompt
	bl imprimir
	pop { r1, r2 }

	mov r4, r2 // Guardo el length
	// Pedir ingreso
	bl pedir_ingreso

	mov r0, #0
	strb r0, [r3, r4]   // Coloco el cero al final de la cadena ingresada.

	pop { r0, r4, r7, lr }
	bx lr
.fnend

//pedir_ingreso:
// Recibe:
//	r1 --> buffer destino
//	r2 --> cantidad de caracteres a leer (sin contar el enter)
// Devuelve:
//	r3 --> palabra ingresada por el usuario
pedir_ingreso:
.fnstart
	push { r0, r7, lr }
	add r2, #1          // A la longitud le sumo 1 para que el "enter" no se quede en el bufer
	mov r0, #0          // En r0 le indicamos que el ingreso es una cadena
	mov r7, #3          // En r7 le indicamos que es una lectura de teclado
	swi 0               // Llamamos a la interrupcion
	mov r3, r1          // palabra que ingresa el usuario.
	pop { r0, r7, lr }
	bx lr
.fnend

// pedir_nombre:
// Recibe:
//	r1 --> buffer en donde se va a guardar
// Devuelve:
//	r3 --> puntero al nombre ingresado
pedir_nombre:
.fnstart
	push { r2, lr }
	ldr r0, =mensaje_nombre
	bl calcular_letra // r1 --> longitud del mensaje
	mov r2, r1
	mov r1, r0
	bl imprimir
	mov r2, #3 // cantidad de caracteres a leer
	bl pedir_ingreso //bl leer_palabra
	pop { r2, lr }
	bx lr
.fnend

//limpiar_mascara
// limpia la máscara que está en r2 la cantidad de caracteres que indique r1
limpiar_mascara:
.fnstart
	push { r3, r4, lr } // DEBERÍA SER UN NÚMERO PAR DE REGISTROS
	mov r3, #'N'                 // caracter con el que se va a llenar la máscara
	mov r4, #0                   // contador
	limpiar_char_mascara:
		strb r3, [r2, r4]
		add r4, #1
		cmp r4, r1
		bne limpiar_char_mascara
	mov r3, #0
	strb r3, [r2, r4]             // coloco el cero que indica el final de la cadena
	pop { r3, r4, lr }
	bx lr
.fnend

//verificar_letras_verdes
// pinta los caracteres verdes en la máscara que está en r2 según la suposición que está en r3 contrastada con la palabra correcta en r0
verificar_letras_verdes:
.fnstart
	push { r4, r5, r6, r7, lr } // DEBERÍA SER UN NÚMERO PAR DE REGISTROS
	mov r6, #'V'                      // letra que va a ser pintada en la máscara
	mov r7, #-1                       // índice
	verificar_misma_ubicacion:
		add r7, #1
		ldrb r4, [r3, r7]             // char de la suposición
		cmp r4, #0                    // fin de la cadena
		beq fin_verificar_verdes
		ldrb r5, [r0, r7]             // char de la palabra correcta
		cmp r4, r5
		beq pintar_char_verde
		bal verificar_misma_ubicacion
	pintar_char_verde:
		strb r6, [r2, r7]
		bal verificar_misma_ubicacion
	fin_verificar_verdes:
		pop { r4, r5, r6, r7, lr }
		bx lr
.fnend

// leer_archivo
// Recibe:
//	r0 --> nombre de archivo
//	r1 --> tamaño de archivo
//	r2 --> buffer destino
// Devuelve:
//  r1 --> buffer con el contenido o -1 si da error.
leer_archivo:
.fnstart
	push { lr }

	// Apertura. Abre el archivo cuyo nombre es el indicado por r0
	push { r1, r2 } // Hacemos un backup de los parámetros porque tenemos que usar estos registros para la interrupción de apertura de archivo.
	mov r7, #5
	mov r1, #0 // Solo lectura
	mov r2, #0 // Permisos
	swi 0

	// Verificación
	cmp r0, #0
	pop { r1, r2 } // Restauración del stack para: a) dejarlo como estaba al entrar en la subrutina, o, b) usar los parámetros de la subrutina en la interrupción de lectura de archivo.
	blt fin_lectura_palabras_error

	// Lectura
	mov r7, #3
	push { r1 } // Idem. push anterior.
	mov r1, r2
	pop { r2 } // Lo restauramos en el registro 2, porque allí es donde la interrupción de lectura de archivo recibe el tamaño de archivo.
	swi 0

	mov r7, #6 // Cierra el file descriptor que quedó en r0
	swi 0
	bal fin_lectura_palabras

	fin_lectura_palabras_error:
		mov r1, #-1

	fin_lectura_palabras:
		pop { lr }
		bx lr
.fnend

// sortear_palabra
// Recibe:
//	r1 --> buffer fuente (palabras separadas por '|')
//	r3 --> buffer destino
sortear_palabra:
.fnstart
	push { r0, r4, r5, r6, lr }

	ldr r5, =palabras_size;
	ldr r6, [r5]

	obtener_random:
		//mov r4, #42 // Número random. COMPLETAR. Debe estar en el rango [0, tamaño del archivo de palabras - 2 - longitud de la última palabra] 
		bl myrand
		cmp r0, r6
		bgt obtener_random
		cmp r0, #0
		blt obtener_random

	mov r4, r0 // Número random obtenido dentro del rango aceptado
	mov r6, #0 // Índice

	// Busco primera palabra que aparece
	buscar_palabra:
		ldrb r5, [r1, r4]
		add r4, #1
		cmp r5, #'|' // Encontró palabra, va a estar en la posición r4
		beq grabar_palabra
		bal buscar_palabra
	grabar_palabra:
		ldrb r5, [r1, r4]
		cmp r5, #'|'
		beq fin_sortear_palabra
		strb r5, [r3, r6]
		add r4, #1
		add r6, #1
		bal grabar_palabra

	fin_sortear_palabra:
		// Se agrega el cero que termina el string.
		//add r6, #1
		mov r5, #0
		strb r5, [r3, r6]
		pop { r0, r4, r5, r6, lr }
		bx lr
.fnend

// verificar_intentos
// Recibe:
//  r1 --> Intentos restantes
// Devuelve:
//	r0 --> 1 si quedan intentos, cero en caso contrario.
verificar_intentos:
.fnstart
	push { lr }
	cmp r1, #1
	blt no_hay_intentos
	bal hay_intentos
	no_hay_intentos:
		mov r0, #0
		bal fin_verificar_intentos
	hay_intentos:
		mov r0, #1
	fin_verificar_intentos:
		mov r2, r1
		add r2, #48 // Convertir intentos restantes a ASCII
		ldr r3, =mensaje_intentos
		strb r2, [r3, #8]

		// Mostrar por pantalla
		push { r0 }
		mov r0, r3
		bl calcular_letra // r1 --> longitud del string
		mov r2, r1
		mov r1, r3
		bl imprimir
		pop { r0 }

		pop { lr }
		bx lr
.fnend

//Pertenece:
	// 1) Se fija si una letra pertence en la palabra
	// 2) En r0 se recibe la direccion de memoria de la plabra que debe adivinar y en r1 se recibe la letra.
	// 3) En r2 se devuelve 1 si la letra esta y 0 si la letra no esta.
Pertenece:
.fnstart
	push { r0, r4, lr }
	mov r2,#0 // Empiezo el contador en 0 por si no esta la letra devuelve 0
	cicloPertenece:
		ldrb r4,[r0],#1 // Obtengo el primer caracter de la palabra
		cmp r4, #0 // me fijo si la palabra termino
		beq salirSubrutinaFalse // si termino sale
		cmp r1, r4 // si no termino, comparo si la letra esta
		beq salirSubrutinaTrue // si esta sale con un true
		bal cicloPertenece // si no esta, vuleve al ciclo.
	salirSubrutinaTrue:
		mov r2, #1 // coloca en r2 1 para saber que esta la letra.
	salirSubrutinaFalse:
		pop { r0, r4, lr }
		bx lr
.fnend

//PintarAmarrillo:
	// 1) Si la letra esta, pero no esta en el lugar correcto se pinta de amarillo
	// 2) En r0 se recibe la direccion de memoria de la plabra que debe adivinar, en r1 la palabra que ingreso el usuario y en r3 la direccion de memoria de la mascara.
	// 3) Devueleve la mascara pintada de amarillo segun las letras.
pintarAmarillo:
.fnstart
	push { r2, r3, r4, r5, r6, r8, lr }
	mov r6, r1
	mov r4,#-1
	mov r8, #'A'
	cicloPintar:
		ldrb r1,[r6],#1 // obtengo la letra que ingreso el usuario
		add r4,#1 // le aumento al indice
		cmp r1,#0 // comparo si el caracter es nulo para saber si termino
		beq salirSubRutina // si es igual sale de la subrutina
		bl Pertenece // sino es igual se fija si pertenece
		cmp r2, #1 // si en r2 devuelve un 1 esta y la pinta
		beq pintarMascara
		bal cicloPintar
	pintarMascara:
		strb r8, [r3, r4]
		bal cicloPintar
	salirSubRutina:
		pop { r2, r3, r4, r5, r6, r8, lr }
		bx lr
.fnend

//Imprimir:
// 1) Muestra por pantalla
// 2) En r1 debe estar la direccion de memoria de lo que deseo imprimir (siempre son cadenas) y en r2 el leng de dicha direccion de memoria.
// 3) En este caso no devuelve nada ya que solo imprime por pantalla
imprimir:
.fnstart
    push { r0, r7, lr } // Guardo r0 y r7 por si se esta usando en el programa
    mov r0, #1          // En r0 le indicamos que la salida es una cadena
    mov r7, #4          // En r7 le indicamos que es una salida por pantalla
    swi 0               // Llamamos a la interrupcion
    pop { r0, r7, lr }  //devuelvo lo que habia en r0 y r7
    bx lr               // Vuelvo al programa
.fnend

// cambiar_color
// Recibe:
//	r1 --> color al que cambiar
cambiar_color:
.fnstart
	push { r2, lr }
	mov r2, #6 // Largo del código de los colores
	bl imprimir
	pop { r2, lr }
	bx lr
.fnend

// informar_resultado
// Recibe:
//	r0 --> máscara
//	r1 --> palabra ingresada
// Devuelve:
//	r3 --> 1 si ganó
informar_resultado:
.fnstart
	push { r4, r5, r6, r7, r8, r9, lr }
	ldr r2, =color_verde
	ldr r3, =color_amarillo
	ldr r4, =color_default
	mov r7, #0 // Índice
	mov r9, #1 // Va a ser el valor de retorno, se inicializa en "ganó" y si se encuentra alguna letra amarilla o negra se cambia a "perdió"
	pintar_caracter:
		ldrb r6, [r1, r7]
		cmp r6, #0
		beq fin_informe_resultado
		// Obtener caracter de máscara para saber qué color pintar.
		ldrb r5, [r0], #1
		cmp r5, #'A'
		beq amarillo
		cmp r5, #'V'
		beq verde
		bal default
	amarillo:
		mov r9, #0 // No es ganador
		push { r1 }
		mov r1, r3
		bl cambiar_color
		pop { r1 }
		bal imprimir_caracter
	verde:
		push { r1 }
		mov r1, r2
		bl cambiar_color
		pop { r1 }
		bal imprimir_caracter
	default:
		mov r9, #0 // No es ganador
		push { r1 }
		mov r1, r4
		bl cambiar_color
		pop { r1 }
		bal imprimir_caracter
	imprimir_caracter:
		mov r8, r1
		add r8, r7 // Guardo en r8 la posición de memoria del caracter que está en el índice r7
		push { r1, r2 }
		mov r1, r8 // Caracter
		mov r2, #1 // Longitud de la cadena
		bl imprimir
		pop { r1, r2 }
		add r7, #1 // Incrementamos el índice
		bal pintar_caracter
	fin_informe_resultado:
		mov r3, r9 // Valor de retorno que indica si ganó
		// Volver al color default
		mov r1, r4
		push { r3 } // Guardamos el registro 3 que vamos a devolver para que no sea sobrescrito por la rutina cambiar_color
		bl cambiar_color
		pop { r3 }
		pop { r4, r5, r6, r7, r8, r9, lr }
		bx lr
.fnend

myrand:
.fnstart
	push {r1, r2, r3, lr}
	ldr r1, =seed @ leo puntero a semilla
	ldr r0, [ r1 ] @ leo valor de semilla
	ldr r2, =const1
	ldr r2, [ r2 ] @ leo const1 en r2
	mul r3, r0, r2 @ r3= seed * 1103515245
	ldr r0, =const2
	ldr r0, [ r0 ] @ leo const2 en r0
	add r0, r0, r3 @ r0= r3+ 12345
	str r0, [ r1 ] @ guardo en variable seed
	/* Estas dos líneas devuelven "seed > >16 & 0x7fff ".
	Con un pequeño truco evitamos el uso del AND */
	LSL r0, # 1
	LSR r0, # 17
	pop {r1, r2, r3, lr}
	bx lr
.fnend

prompt_final:
.fnstart
	push { r1, r2, r4, lr }
	ldr r1, =mensaje_jugar
	mov r2, #32
	bl imprimir
	mov r2, #1
	ldr r1, =eleccion
	bl pedir_ingreso // r3 --> palabra ingresada
	ldrb r4, [r3]
	cmp r4, #'y'
	pop { r1, r2, r4, lr }
	beq yes
	bal no
	yes:
		mov r3, #1
		bx lr
	no:
		mov r3, #0
		bx lr
.fnend

// grabar_ranking
// Recibe:
//	r0 --> nombre del jugador
grabar_ranking:
.fnstart
	push { r1, r2, r3, r4, r5, r6, lr }
	mov r2, #0 // Índice
	ldr r1, =linea_ranking // Línea a escribir
	escribir_nombre:
		ldrb r3, [r0, r2] // Traigo el caracter de nombre
		strb r3, [r1, r2] // Lo coloco en la línea
		add r2, #1
		cmp r2, #3
		blt escribir_nombre

	// Espacio separador
	mov r3, #' '
	strb r3, [r1, r2]
	add r2, #1

	// Puntuación
	mov r4, #0 // Índice del puntaje
	ldr r0, =puntaje
	escribir_puntaje:
		ldrb r3, [r0, r4] // Traigo el caracter de puntaje
		strb r3, [r1, r2] // Lo coloco en la línea
		add r2, #1
		add r4, #1
		cmp r4, #2
		blt escribir_puntaje

	// newline
	mov r3, #'\n'
	strb r3, [r1, r2]
	add r2, #1

	// Escribo en un archivo la línea seguido de las dos primeras líneas del ranking.
	// Abrir archivo
	push { r1 } // Guardo la línea
	ldr r0, =ranking_name
	mov r1, #1
	mov r2, #438
	mov r7, #5
	swi 0
	cmp r0, #0
	blt fin_ranking
	mov r6, r0 // Me guardo el fd en r6
	pop { r1 }

	// Escribo la linea
	mov r0, r6
	mov r7, #4 // write, en r1 debe estar la línea.
	mov r2, #7 // Tamaño de la línea
	swi 0

	// Escribo el último ranking
	mov r0, r6
	add r1, #7  // Salto la última línea, entro al buffer.
	mov r7, #4
	mov r2, #14 // Escribo dos líneas del buffer.
	swi 0

	// Cierro el archivo
	mov r0, r6
	mov r7, #6
	swi 0

	fin_ranking:
		bx lr
		pop { r1, r2, r3, r4, r5, r6, lr }
.fnend

.global main
main:
	// Cargo el archivo a una lista de palabras en memoria.
	ldr r0, =palabras_name // Nombre de archivo
	ldr r4, =palabras_size // Tamaño de archivo (dirección)
	ldr r1, [r4]           // Tamaño de archivo
	ldr r2, =palabras      // Buffer destino
	bl leer_archivo       // r1 --> Buffer con las palabras
	cmp r0, #-1
	beq fin

	// Obtengo una palabra al azar
	// ??? COMPLETAR
	ldr r3, =palabra   // Buffer destino
	bl sortear_palabra // r3 --> Puntero a palabra
	mov r4, r3

	// Cuento la cantidad de letras, recibo la longitud en r1.
	mov r0, r4        // Palabra
	bl calcular_letra // r1 --> Longitud de la palabra
	mov r5, r1

	// Preparar el prompt
	ldr r0, =prompt
	mov r1, r5
	add r1, #48 // Convierto cantidad de caracteres en caracter ASCII
	strb r1, [r0, #23]

	ldr r6, =mascara

	ldr r0, =intentos
	ldr r8, [r0]

	juego:
		mov r1, r5         // Longitud de la palabra
		mov r2, r6         // Buffer destino
		bl limpiar_mascara

		// Pido que el usuario ingrese una palabra.
		ldr r1,=color_default
		bl cambiar_color
		ldr r1, =suposicion // Buffer destino
		mov r2, r5          // Longitud
		bl leer_palabra     // r3 --> Puntero a buffer destino
		mov r11, r3

		// Verificación de la palabra

		// Verifico letras amarillas
		mov r0, r4  // Palabra correcta
		mov r1, r11 // Palabra ingresada
		mov r3, r6  // Máscara
		bl pintarAmarillo

		// Verifico letras verdes
		mov r0, r4  // Palabra correcta
		mov r2, r6  // Máscara
		mov r3, r11 // Palabra ingresada
		bl verificar_letras_verdes

		// Informo resultado
		mov r0, r6  // Máscara
		mov r1, r11 // Palabra ingresada
		bl informar_resultado // r3 --> Ganó el juego
		cmp r3, #1
		beq fin_juego

		// Acá se decide si seguir el juego o salir del bucle.
		mov r1, r8            // Intentos restantes
		bl verificar_intentos // r0 --> Sigue jugando
		cmp r0, #0
		beq preguntar

		sub r8, #1
		bal juego

	preguntar:
		bl prompt_final
		cmp r3, #1
		beq main
		bal fin

	fin_juego:
		// Pido nombre.
		ldr r1, =nombre // Buffer destino
		bl pedir_nombre // r3 --> Puntero a buffer destino
		mov r9, r3

		// Calculo puntos
		mov r0, r8         // Intentos restantes
		bl calcular_puntos // r2 --> Puntuación

		//Mostrar puntos
		ldr r0,=mensaje_final
		ldr r3,=puntaje
		bl mostrar_puntaje

		// Cargo el archivo de ranking
		ldr r0, =ranking_name   // Nombre de archivo
		ldr r4, =ranking_size   // Tamaño de archivo (dirección)
		ldr r1, [r4]            // Tamaño de archivo
		ldr r2, =buffer_ranking // Buffer destino
		bl leer_archivo         // r1 --> Buffer con el ranking
		cmp r0, #-1
		beq fin

		// Grabo ranking
		mov r0, r9
		bl grabar_ranking

		// Muestro ranking
		// Cargo el archivo de ranking ahora modificado
		ldr r0, =ranking_name   // Nombre de archivo
		ldr r4, =ranking_size   // Tamaño de archivo (dirección)
		ldr r1, [r4]            // Tamaño de archivo
		ldr r2, =buffer_ranking // Buffer destino
		bl leer_archivo         // r1 --> Buffer con el ranking
		cmp r0, #-1
		beq fin

		ldr r2, [r4] // Tamaño de archivo
		bl imprimir

	fin:
		mov r7, #1
		swi 0
