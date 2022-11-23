

const date = new Date();


function adicionaZero(numero){
    if (numero <= 9) 
        return "0" + numero;
    else
        return numero; 
  }
  
  function Hora(){
  return adicionaZero(date.getHours()) + ':'+adicionaZero(date.getMinutes());
  }
  


function DaiDaSemana(){
    if (date.getDay()==1){
        return 'segunda'
    }
    if (date.getDay()==2){
        return 'terca'
    }
    if (date.getDay()==3){
        return 'quarta'
    }
    if (date.getDay()==4){
        return 'quinta'
    }
    if (date.getDay()==5){
        return 'sexta'
    }
    if (date.getDay()==6){
        return 'sabado'
    }
    if (date.getDay()==7){
        return 'domingo'
    }

}

function ValidaDaiDaSemana(){
    if (date.getDay()==1){
        return 'segundaa'
    } 
    if (date.getDay()==2){
        return 'tercaa'
    }
    if (date.getDay()==3){
        return 'quartaa'
    }
    if (date.getDay()==4){
        return 'quintaa'
    }
    if (date.getDay()==5){
        return 'sextaa'
    }
    if (date.getDay()==6){
        return 'sabadoo'
    }
    if (date.getDay()==7){
        return 'domingoo'
    }
  
  }
  
  
export function HorarioAbertura(data){
    if (data.length==0){
        return '';
      } else {
        var Semana = DaiDaSemana();
        var Semanaa = ValidaDaiDaSemana();

        if (data[0]['config_'+Semanaa]==true){
            return data[0][Semana+'_manha_de'];
        }

        if (data[0]['config_'+Semana]){
            return data[0][Semana+'_tarde_de'];
        }
        
      }
}

export function HorarioFechamento(data){
    if (data.length==0){
        return '';
      } else {
        var Semana = DaiDaSemana();
        var Semanaa = ValidaDaiDaSemana();

        if (data[0]['config_'+Semanaa]==true){
            return data[0][Semana+'_manha_ate'];
        }

        if (data[0]['config_'+Semana]){
            return data[0][Semana+'_tarde_ate'];
        }
        
      }
}


export function ValidaAbertura(data){
    var Semana = DaiDaSemana();
    var Semanaa = ValidaDaiDaSemana();

    if (data.length==0){
      return false;
    } else {
      console.log(data[0])
      // console.log(Hora());
      var HoraAbertura = 0;
      var MinutoAbertura = 0;
      var HoraFechamento = 0;
      var MinutoFechamento = 0;
      var ArrayAbertura = [];
      var ArrayFechamento = [];
      var status = false;

      if (data[0]['config_'+Semanaa]==true){
        //Manha
        ArrayAbertura = data[0][Semana+'_manha_de'].split(":");
        ArrayFechamento = data[0][Semana+'_manha_ate'].split(":");

        HoraAbertura = ArrayAbertura[0];
        MinutoAbertura = ArrayFechamento[1];

        HoraFechamento = ArrayFechamento[0];
        MinutoFechamento = ArrayFechamento[0];

        if (date.getHours() >=HoraAbertura && date.getMinutes() >= MinutoAbertura) {          
          status = true;

          if (date.getHours() >= HoraFechamento) {
            status = false;
  
            if (MinutoFechamento > 0){
              if (date.getMinutes() >= MinutoFechamento){
                status = false
              } else {
                
                status = true; 
              }
            }
  
  
          } else {
             status = true;
          }

        } else {          
          status = false;
        }  

      }

      if (data[0]['config_'+Semana]){
        //Atarde
        ArrayAbertura = data[0][Semana+'_tarde_de'].split(":");
        ArrayFechamento = data[0][Semana+'_tarde_ate'].split(":");

        HoraAbertura = ArrayAbertura[0];
        MinutoAbertura = ArrayFechamento[1];

        HoraFechamento = ArrayFechamento[0];
        MinutoFechamento = ArrayFechamento[0];

        if (date.getHours() >=HoraAbertura && date.getMinutes() >= MinutoAbertura) {          
          status = true;

          if (date.getHours() >= HoraFechamento) {
            status = false;
  
            if (MinutoFechamento > 0){
              if (date.getMinutes() >= MinutoFechamento){
                status = false
              } else {
                
                status = true; 
              }
            }
  
  
          } else {
             status = true;
          }

        } else {          
          status = false;
        }
               
      }

      // console.log(status);

      return status;


    }
    
}