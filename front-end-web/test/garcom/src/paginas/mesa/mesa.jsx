import { InputText } from "primereact/inputtext";
import Cabecalho from "../../componentes/cabecalho/cabecalho";
import CardMesa from "../../paginas/home/card";


function Mesa() {

    
    const numbers = [1, 2, 3, 4, 5,6,7,8,9,10,11,12,13,14,15];
    var totalMesa = 0;

    const Cards = numbers.map((dados)=>{
        totalMesa = totalMesa + dados;
        return <CardMesa key={dados} descricao="Mesa 1" total={dados} status={1}/>
        // console.log(dados);
    })

    return (
        <>
        <Cabecalho/>
        
        <div className="field col-12 md:col-4">
        <span className="p-float-label mt-3 ">
            {/* value={value1} onChange={(e) => setValue1(e.target.value)} */}
            <InputText id="inputtext"  className="w-full"/>
            <label htmlFor="inputtext">Comanda / Mesa</label>
        </span>
        </div>

        <div className="card">
            <div className="flex flex-wrap justify-content-center card-container blue-container max-h-500px bg-black">
            
               
           {Cards}
            

            </div>
        </div>   

        <div className="relative bg-blue-200 w-full h-9rem m-0 bottom-0 md:my-0 border-round ">
            <div className="absolute bottom-0 left-0 bg-blue-500 text-white font-bold flex align-items-center justify-content-center  h-4rem border-round  w-full">Total Consumação R$ {totalMesa.toLocaleString('pt-br', {minimumFractionDigits: 2})}</div>
        </div>          

        
        </>
    );
  }
  
  export default Mesa;

  