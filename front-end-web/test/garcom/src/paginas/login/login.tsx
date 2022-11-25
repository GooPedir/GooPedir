import React, { useEffect, useState } from 'react';
import { useFormik } from 'formik';
import { InputText } from 'primereact/inputtext';
import { Button } from 'primereact/button';
import { Dropdown } from 'primereact/dropdown';
import { Calendar } from 'primereact/calendar';
import { Password } from 'primereact/password';
import { Checkbox } from 'primereact/checkbox';
import { Dialog } from 'primereact/dialog';
import { Divider } from 'primereact/divider';
import { classNames } from 'primereact/utils';
import { CountryService } from './CountryService';
import './FormDemo.css';



function Login() {

  return (
    <div className="form-demo">
    {/* <Dialog visible={showMessage} onHide={() => setShowMessage(false)} position="top" footer={dialogFooter} showHeader={false} breakpoints={{ '960px': '80vw' }} style={{ width: '30vw' }}>
        <div className="flex align-items-center flex-column pt-6 px-3">
            <i className="pi pi-check-circle" style={{ fontSize: '5rem', color: 'var(--green-500)' }}></i>
            <h5>Registration Successful!</h5>
            <p style={{ lineHeight: 1.5, textIndent: '1rem' }}>
                Your account is registered under name <b>{formData.name}</b> ; it'll be valid next 30 days without activation. Please check <b>{formData.email}</b> for activation instructions.
            </p>
        </div>
    </Dialog> */}

    <div className="flex justify-content-center">
        <div className="card">
            <h5 className="text-center">Garçom GooPedir</h5>
            <form className="p-fluid">
                <div className="field">
                    <span className="p-float-label">
                        <InputText id="name" name="name"  autoFocus />
                        <label htmlFor="name">Usuário</label>
                    </span>
                    {/* {getFormErrorMessage('name')} */}
                </div>
                <div className="field">
                    <span className="p-float-label p-input-icon-right">
                        {/* <i className="pi pi-envelope" /> */}
                        <InputText id="email" name="email"/>
                        <label htmlFor="email" >Senha</label>
                    </span>
                    {/* {getFormErrorMessage('email')} */}
                </div>           

                <Button type="submit" label="Login" className="mt-2" />
            </form>
        </div>
    </div>
</div>
  );
}

export default Login;
