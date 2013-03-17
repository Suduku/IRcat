#include <avr/sleep.h>
#include <avr/wdt.h>

#define IR_Pin PORTB // Registre du PORTB Définit en Ecriture et Lecture
#define IR_Led 3 // Définit le pin de la Led IR > Pin2 (PB3)

byte Code_IR = B01010101;//Code IR envoyé
int WDT_Time = 9;// Réglage du délais de veille: 0=16ms, 1=32ms, 2=64ms, 3=125ms, 4=250ms, 5=500ms, 6=1 sec, 7=2 sec, 8=4 sec, 9= 8sec
byte WDP_Set; // Réglage WDP (bit de réglage délais de veille)

void setup(){
   Set_Time_WDT(WDT_Time); //Délais de veille
   OSCCAL = 0x56; // Calibration Oscillateur Interne de l'ATtiny85, voir Tiny Tuner
   DDRB |= _BV(IR_Led); // Met le pin IRled en OUTPUT > 0000 1000
   ADCSRA = 0; // Désactive l'ADC (Analog to Digital Converter) pour économiser du courant en mode veille
}
	
void loop(){
   IRCode(); // Lance la Boucle IRCode
   DDRB &= ~_BV(IR_Led); // Mets le port de la Led en INPUT pour économiser du courant
   Veille(); // Mise en veille de l'ATtiny
   DDRB |= _BV(IR_Led); // Remet le port en OUTPUT
}

void Veille() { // Met l'ATtiny en veille
   MCUSR &= ~(1<<WDRF);  // Met à 0 le bit "Watchdog Reset Flag" dans le Registre MCU (Registre de statut) qui est remis à 1 quand l'ATtiny sort de veille (indicateur sur la façon de sortir du reset)
   WDTCR = _BV (WDCE) | _BV (WDE); // Régle les bits WDE et WDCE sur 1 du WDTCR (Watchdog Timer Control Register) pour pouvoir configurer les délais de mise en veille
   WDTCR = _BV (WDIE) | WDP_Set; // Met le bit WDIE sur 1, ce qui active l'interruption du watchdog et met le bit WDE à 0, les bits WDP sont réglé et à la fin du délais configuré le Watchdog fait un reset
   wdt_reset();
   set_sleep_mode (SLEEP_MODE_PWR_DOWN);  //ZZZzz..ZZzzz..Zzz
   sleep_enable();
   sleep_cpu ();   
   sleep_disable();
}
	
void pulseIR(long microsecs){ // Envoit les pulsations à 38Khz durant le temps définit par les microsecondes de PulseIR
   while (microsecs >= 0){ // Tant que les microsecondes de la valeur pulseIR n'ont pas atteint 0 on continu
     IR_Pin &= ~_BV(IR_Led); // Met le Pin2 (PB3) à l'état haut
     delayMicroseconds(13); //38Khz = 13 microsecondes haut + 13 microsecondes bas
     IR_Pin |= _BV(IR_Led); // Met le Pin2 (PB3) à l'état bas
     delayMicroseconds(13); //38Khz = 13 microsecondes haut + 13 microsecondes bas
     microsecs -= 26; // on Retire 26 microsecondes de la valeur PulseIR
    }
}
	
void IRCode() {
	pulseIR(3580);
	delay(26);
	for(int x = 0 ; x < 8; x++){
		if ( bitRead(Code_IR, x) == 1){
		pulseIR(780);
		delayMicroseconds(2000);
		}
		else{
		pulseIR(390);
		delayMicroseconds(1000);
		}
	}
}
	
void Set_Time_WDT(int Time){ // Conversion valeur du délais de veille en Décimal pour régler les bits WDP
   if ( Time == 8 ) WDP_Set = ( Time * 4 ) ;
   if ( Time == 9 ) WDP_Set = ( Time * 4 ) + 1;
   else WDP_Set = Time;
}

ISR(WDT_vect){ // Vecteur Watchdog lancé à la fin du délais configuré
   wdt_disable();
}
