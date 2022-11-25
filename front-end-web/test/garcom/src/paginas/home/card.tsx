import { Navigate, Route} from 'react-router-dom';

interface Props{
  descricao: string;
  total: number;
  status: number;

}




// function CardMesa(props) {
   const CardMesa = ({descricao,total,status}:Props) =>{
    
    var nomeclass = "bg-green-500 font-bold text-white h-8rem w-10rem border-round m-1";
    var descricaoStatus = "Livre";

    if (status==1){
      nomeclass = "bg-blue-500 font-bold text-white h-8rem w-10rem border-round m-1";
      descricaoStatus = "Em Consumação";
   } 


   function SelecionouMesa(){
    console.log('Mesa')
    return  <Navigate to="/login" replace={true} />
    
  }
   

   return (
       <>
       
       {/* <h1>{descricao}</h1> */}

{/* // max-h-200px min-h-100px  */}
{/* flex align-items-center justify-content-center   m-2 border-round */}
        

       <div className={nomeclass} onClick={SelecionouMesa}>
       {/* <div className="text-center">XX</div> */}
       <p className="text-center ">{descricaoStatus}</p>
       <p className="text-center ">{descricao}</p>
       <p className="text-center ">R$ {total.toLocaleString('pt-br', {minimumFractionDigits: 2})}</p>



       </div>

       
       </>
   );
 }
 
 export default CardMesa;
