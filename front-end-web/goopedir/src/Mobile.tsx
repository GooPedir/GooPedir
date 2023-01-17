import axios from "axios";
import { useState } from "react";
import Global from "./estilo/global";
import TopoMobile from "./mobile/topo/topo"; 

var start = false;

function Mobile() {
const BaseURL = "http://192.168.10.195:2121/";

const [Mesas, setMesas] = useState([]);

const API = axios.create({
    baseURL: BaseURL,
  }) 

  if (start){
    if (Mesas.length==0){
        API.get('v1/mesas/all').then(
            function (response) {
            setMesas(response.data)
            console.log(response.data) 
        
            })        
    }
  } else {
    start = true;
      API.get('v1/mesas/all').then(
         function (response) {
    console.log(response.data) 
         setMesas(response.data)

    })
  }






  return (
    <>  
    <Global/>
    
    <TopoMobile data={Mesas}/>

   </>
  );
}


export default Mobile;
